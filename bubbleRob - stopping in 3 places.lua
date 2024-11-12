sim=require'sim'
simUI=require'simUI'

function sysCall_init()
    bubbleRobBase=sim.getObject('.')
    leftMotor=sim.getObject("../bubbleRob_leftMotor")
    rightMotor=sim.getObject("../bubbleRob_rightMotor")
    noseSensor=sim.getObject("../bubbleRob_sensingNose")
    collisionSensor=sim.getObject("../collisionSensor") 
    minMaxSpeed={50*math.pi/180,300*math.pi/180} 
    backUntilTime=-1 -- Indicates if bubbleRob is in forward or backward mode
    collisionPauseTime=-1 -- Time to pause after detecting a color other than black
    robotMoving=true -- Flag to check if the robot is moving
    collisionSensorDisabledTime=-1 -- Time when the collision sensor should be re-enabled
    collisionDetected=false -- Flag to track if collision was detected

    floorSensorHandles={-1,-1,-1}
    floorSensorHandles[1]=sim.getObjectHandle("../leftSensor")
    floorSensorHandles[2]=sim.getObjectHandle("../middleSensor") 
    floorSensorHandles[3]=sim.getObjectHandle("../rightSensor")

   
    xml = '<ui title="'..sim.getObjectAlias(bubbleRobBase,1)..' speed" closeable="false" resizeable="false" activate="false">'..[[
    <hslider minimum="0" maximum="100" on-change="speedChange_callback" id="1"/>
    <label text="" style="* {margin-left: 300px;}"/>
    </ui>
    ]]
    ui=simUI.create(xml)
    speed=(minMaxSpeed[1]+minMaxSpeed[2])*0.5
    simUI.setSliderValue(ui,1,100*(speed-minMaxSpeed[1])/(minMaxSpeed[2]-minMaxSpeed[1]))
end

function speedChange_callback(ui, id, newVal)
    speed=minMaxSpeed[1]+(minMaxSpeed[2]-minMaxSpeed[1])*newVal/100
end

function sysCall_actuation()
   
    local result, data = sim.readVisionSensor(collisionSensor)
    
    if result >= 0 and data[11] > 0.1 then 
        if not collisionDetected then
            -- Stop the robot and wait for 4 seconds
            collisionDetected = true -- Flag that a collision was detected
            collisionSensorDisabledTime = sim.getSimulationTime() + 4 -- Disable the sensor for 4 seconds
            robotMoving = false -- Stop the robot
            sim.setJointTargetVelocity(leftMotor, 0)
            sim.setJointTargetVelocity(rightMotor, 0)
        end
    end

    -- If the collision sensor is disabled, check if the 4 seconds have passed
    if collisionDetected and sim.getSimulationTime() > collisionSensorDisabledTime then
        -- After 4 seconds enable the sensor again and let robot move (hope so)
        collisionDetected = false -- Reset the collision flag
        robotMoving = true -- Allow the robot to move again
    end

    -- If the robot is moving, follow the line
    if robotMoving then
        -- Line-following logic
        local linesensor = {false, false, false}
        for i = 1, 3 do
            local res, lineData = sim.readVisionSensor(floorSensorHandles[i])
            if res >= 0 then
                linesensor[i] = (lineData[11] < 0.33)
            end
        end

        
        local rightV = speed * 2
        local leftV = speed * 2


        if linesensor[1] then leftV = 0.6 * speed end
        if linesensor[3] then rightV = 0.5 * speed end
        if linesensor[1] and linesensor[3] then
            backUntilTime = sim.getSimulationTime() + 2
        end

    
        if backUntilTime < sim.getSimulationTime() then
            sim.setJointTargetVelocity(leftMotor, leftV)
            sim.setJointTargetVelocity(rightMotor, rightV)
        else
            sim.setJointTargetVelocity(leftMotor, speed / 2)
            sim.setJointTargetVelocity(rightMotor, speed / 8)
        end
    end
end

function sysCall_cleanup()
    simUI.destroy(ui)
end
