CLASS.Base = "_base"

CLASS.Name = "Fast Zombie"
CLASS.TranslationName = "class_fast_zombie"

CLASS.Type = ZTYPE_MINIBOSS

CLASS.SWEP = "weapon_zsz_fastzombie"
CLASS.Speed = 350
CLASS.Points = 10

CLASS.Model = Model("models/player/zombie_fast.mdl")

CLASS.PainSounds = {"NPC_FastZombie.Pain"}
CLASS.DeathSounds = {"npc/fast_zombie/leap1.wav"} --{"NPC_FastZombie.Die"}

CLASS.VoicePitch = 0.75

CLASS.Hull = {Vector(-16, -16, 0), Vector(16, 16, 58)}
CLASS.HullDuck = {Vector(-16, -16, 0), Vector(16, 16, 32)}
CLASS.ViewOffset = Vector(0, 0, 50)
CLASS.ViewOffsetDucked = Vector(0, 0, 24)

CLASS.NoFallDamage = true
CLASS.NoFallSlowdown = true

CLASS.StepScale = 0.75

CLASS.Health = 275

local math_ceil = math.ceil
local ACT_HL2MP_RUN_KNIFE = ACT_HL2MP_RUN_KNIFE


function CLASS:CalcMainActivity(pl, velocity)
	if pl:WaterLevel() >= 3 then
		return self.act_Swim, -1
	end

	local wep = pl:GetActiveWeapon()
	if wep:IsValid() then
		if wep.IsClimbing and wep:IsClimbing() then
			return self.act_Climb, -1
		elseif wep.IsLeaping and wep:IsLeaping() then
			return self.act_Leap, -1
		elseif wep.IsAlting and wep:IsAlting() and not pl:Crouching() then
			return ACT_HL2MP_RUN_KNIFE, -1
		end
	end

	if velocity:Length2DSqr() <= 1 then
		if pl:Crouching() and pl:OnGround() then
			return self.act_Crouch, -1
		end

		return ACT_HL2MP_RUN_ZOMBIE_FAST, -1
	end

	if pl:Crouching() and pl:OnGround() then
		return self.act_CrouchWalk - 1 + math_ceil((CurTime() / 4 + pl:EntIndex()) % 3), -1
	end

	return ACT_HL2MP_RUN_KNIFE, -1
end

function CLASS:UpdateAnimation(pl, velocity, maxseqgroundspeed)
	local wep = pl:GetActiveWeapon()
	if not wep:IsValid() or not wep.GetClimbing or not wep.GetPounceTime then return end

	if wep.GetSwinging and wep:GetSwinging() then
		if not pl.PlayingFZSwing then
			pl.PlayingFZSwing = true
			pl:AnimRestartGesture(GESTURE_SLOT_ATTACK_AND_RELOAD, ACT_GMOD_GESTURE_RANGE_FRENZY)
		end
	elseif pl.PlayingFZSwing then
		pl.PlayingFZSwing = false
		pl:AnimResetGestureSlot(GESTURE_SLOT_ATTACK_AND_RELOAD) --pl:AnimRestartGesture(GESTURE_SLOT_ATTACK_AND_RELOAD, ACT_GMOD_GESTURE_RANGE_FRENZY, true)
	end

	if wep:GetClimbing() then
		local vel = pl:GetVelocity()
		local speed = vel:LengthSqr()
		if speed > 64 then --8^2
			pl:SetPlaybackRate(math_Clamp(speed / 25600, 0, 1) * (vel.z < 0 and -1 or 1)) --160^2
		else
			pl:SetPlaybackRate(0)
		end

		return true
	end

	if wep.GetPounceTime and wep:GetPounceTime() > 0 then
		pl:SetPlaybackRate(0.25)

		if not pl.m_PrevFrameCycle then
			pl.m_PrevFrameCycle = true
			pl:SetCycle(0)
		end

		return true
	elseif pl.m_PrevFrameCycle then
		pl.m_PrevFrameCycle = nil
	end

	if not pl:OnGround() or pl:WaterLevel() >= 3 then
		pl:SetPlaybackRate(1)

		if pl:GetCycle() >= 1 then
			pl:SetCycle(pl:GetCycle() - 1)
		end

		return true
	end
end

function CLASS:DoAnimationEvent(pl, event, data)
	if event == PLAYERANIMEVENT_ATTACK_PRIMARY then
		pl:AnimRestartGesture(GESTURE_SLOT_ATTACK_AND_RELOAD, ACT_GMOD_GESTURE_RANGE_ZOMBIE_SPECIAL, true)
		return ACT_INVALID
	elseif event == PLAYERANIMEVENT_RELOAD then
		return ACT_INVALID
	end
end

if not CLIENT then return end

CLASS.Icon = "zombiesurvival/killicons/fastzombie"
