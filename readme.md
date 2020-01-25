 
aerotest

King of the sky - eagle a mob for mobkit

implementation:

    it's done using low level behaviors as opposed to plain functions, because pitch/roll changes must be gradual so there's a need to maintain states over time.

    function aerotest.lq_fly_pitch(self,lift,pitch,roll,acc,anim)
        this one tries to maintain constant pitch. Flight looks stable, but the thing can stall and fall if velocity too low. The example uses this one exclusively.
        
    function aerotest.lq_fly_aoa(self,lift,aoa,roll,acc,anim)
        tries to maintain constant angle of attack. makes them less prone to stalling, but they tend to oscillate after abrupt changes of flight parameters. this one's very WIP.
        
    params:

        lift: [number]
        multiplier for lift. faster objects need less, slower need more. typical value: 0.6 for speeds around 4 m/s

        pitch: [degrees]
        angle between the longitudinal axis and horizontal plane. typical range: <-15.15>

        aoa:
        [degrees] angle of attack - the angle between the longitudinal axis and velocity vector.

        roll: [degrees]
        bank angle. positive is right, negative is left, this is how they turn. if set too large they'll loose height rapidly

        acc: [number]
        propulsion. use with positive pitch to make them fly level or climb, set it to 0 with slight negative pitch to make
        them glide. typical value: around 1.0

        anim: [string]
        animation.

The example uses two simple high level behaviors to keep them between 18 and 24 nodes above ground, seems good already for ambient type flying creatures.
warning: never set_velocity when using these behaviors.
