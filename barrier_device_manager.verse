# THANKS FOR CHEKING OUT @GHOSTUEP ON X #

# FOLLOW THE TUTORIAL ON MY X PAGE #

using { /Fortnite.com/Devices }
using { /Verse.org/Simulation }
using { /UnrealEngine.com/Temporary/Diagnostics }
using { /Fortnite.com/Devices/CreativeAnimation }
using { /UnrealEngine.com/Temporary/SpatialMath }
using { /Fortnite.com/Devices/CreativeAnimation/InterpolationTypes }
using { /Fortnite.com/Characters }
using { /Verse.org/Random }

BarriersClass:=class<concrete>():

    PropsSettingsMSG<public><localizes>:message = "Crate to be animated"
    @editable{ToolTip := PropsSettingsMSG} CrateProp : creative_prop = creative_prop{}
    
    PropsSettings2MSG<localizes>:message = "Collectable Prop"
    @editable{ToolTip := PropsSettings2MSG} CollectableProp : creative_prop_asset = DefaultCreativePropAsset

    PropsSettings3MSG<localizes>:message = "Animation Settings"
    @editable{ToolTip := PropsSettings3MSG} AnimationSettings : PropSettings = PropSettings{}

    PropsSettings4MSG<localizes>:message = "Trigger to Activate on HIT"
    @editable{ToolTip := PropsSettings4MSG} OnHitTrigger : trigger_device = trigger_device{}

    InitBarrier():void=
        AnimationSettings.PropManipulator.DamagedEvent.Subscribe(OnHitEvent)

    OnHitEvent(A:agent):void=
        if (P:=player[A]):
            OnPropHit(P)

    OnPropHit(P:player):void=
        if (AnimationSettings.PropAnimation.Enabled?) {InitAnimation()}
        if (AnimationSettings.PropAnimation.Enabled?) {spawn {StartColletableAnimation(P)}}
        spawn {SpawnVFX()}
        OnHitTrigger.Trigger(P)

    StartColletableAnimation(P:player)<suspends>:void=
        if:
            Character := P.GetFortCharacter[]
        then:
            Location:=Character.GetTransform()
            if (Prop:=SpawnProp(CollectableProp, CrateProp.GetTransform().Translation, CrateProp.GetTransform().Rotation)(0)?):
                Prop.MoveTo(GetRandomPosition(Location), Location.Rotation, 0.2)
                var Time : float = 1.5
                loop:
                    if (not Prop.IsValid[] or not Character.IsActive[]):
                        break
                    Prop.MoveTo(GetRandomPosition(Character.GetTransform()), Location.Rotation, 0.15)
                    set Time -= 0.15
                    if (Time <= 0.0):
                        Prop.MoveTo(Character.GetTransform().Translation, Location.Rotation, 0.2)
                        Prop.Dispose()

    GetRandomPosition(Location:transform):vector3=
        LocationX:=Location.Translation.X
        LocationY:=Location.Translation.Y
        LocationZ:=Location.Translation.Z + AnimationSettings.ColletableAnimation.ZAmount
        return vector3{X:=LocationX, Y:=LocationY, Z:=LocationZ}

    SpawnVFX()<suspends>:void=
        AnimationSettings.VFXSpawner.Enable()
        Sleep(0.5)
        AnimationSettings.VFXSpawner.Disable()

    InitAnimation() : void=
        TargetScaleX : float = AnimationSettings.PropAnimation.AmountX
        TargetScaleY : float = AnimationSettings.PropAnimation.AmountY
        TargetScaleZ : float = AnimationSettings.PropAnimation.AmountZ
        InverseTargetScaleX : float = 1.0/AnimationSettings.PropAnimation.AmountX
        InverseTargetScaleY : float = 1.0/AnimationSettings.PropAnimation.AmountY
        InverseTargetScaleZ : float = 1.0/AnimationSettings.PropAnimation.AmountZ

        DownScaleKeyFrame : keyframe_delta = keyframe_delta{
            DeltaLocation := vector3{ X:= 0.0, Y:= 0.0, Z:= 0.0}
            DeltaRotation := IdentityRotation()
            DeltaScale := vector3{X:=TargetScaleX, Y:=TargetScaleY, Z:=TargetScaleZ}
            Time := AnimationSettings.PropAnimation.Time / 2.0
            Interpolation := EaseIn
        }
        UpScaleKeyFrame : keyframe_delta = keyframe_delta{
            DeltaLocation := vector3{ X:= 0.0, Y:= 0.0, Z:= 0.0}
            DeltaRotation := IdentityRotation()
            DeltaScale := vector3{X:=InverseTargetScaleX, Y:=InverseTargetScaleY, Z:=InverseTargetScaleZ}
            Time := AnimationSettings.PropAnimation.Time / 2.0
            Interpolation := EaseIn
        }
        AnimationKeyFrames := array{DownScaleKeyFrame,UpScaleKeyFrame}
        if(PropAnimController := CrateProp.GetAnimationController[]):
            AnimState := PropAnimController.GetState()
            if(AnimState = animation_controller_state.AnimationNotSet or AnimState = animation_controller_state.Stopped):
                PropAnimController.SetAnimation(AnimationKeyFrames,?Mode := animation_mode.OneShot)
                PropAnimController.Play()

PropSettings:=struct<concrete>():

    ManipulatorMSG<public><localizes>:message = "Prop Manipulator para Pop"
    @editable{ToolTip := ManipulatorMSG} PropManipulator : prop_manipulator_device = prop_manipulator_device{}

    VFXOnhitMSG<public><localizes>:message = "VFX para hit na Prop"
    @editable{ToolTip := VFXOnhitMSG} VFXSpawner : vfx_spawner_device = vfx_spawner_device{}

    AnimationMSG<public><localizes>:message = "Configurações da animação das Props"
    @editable{ToolTip := AnimationMSG} PropAnimation : PropAnimationSetting = PropAnimationSetting{}

    Animation2MSG<public><localizes>:message = "Configurações da animação dos Coletáveis"
    @editable{ToolTip := Animation2MSG} ColletableAnimation : ColletableAnimationSetting = ColletableAnimationSetting{}

ColletableAnimationSetting:=struct<concrete>():
    @editable Enabled : logic = false
    @editable ZAmount : float = 105.0

PropAnimationSetting:=struct<concrete>():
    @editable Enabled : logic = false
    @editable AmountX : float = 1.0
    @editable AmountY : float = 1.0
    @editable AmountZ : float = 1.0
    @editable Time : float = 1.0

barrier_manager_device := class(creative_device):

    @editable Crates : []BarriersClass = array{}

    OnBegin<override>()<suspends>:void=
        for (B:Crates):
            B.InitBarrier()
