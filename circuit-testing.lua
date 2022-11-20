-- Put your global variables here.

MOVE_STEPS = 5 --make decisions every 5 step
MAX_VELOCITY = 5 --velocity 
FILENAME = "Qtable-circuit.csv" --q table file name
WHEEL_DIST = -1 -- distance between wheels
n_steps = 0 -- counter


--- This function is executed every time you press the 'execute' button.
function init()

  Qlearning = require "Qlearning"
	
	WHEEL_DIST = robot.wheels.axis_length
  
  total_state_acquisition = 0 -- total number of times that the robot is on the black and the white part of arena
  on_white_circuit_acquisition = 0 --- numeber of times that the robot is in correct part of arena, the white part
  
	local left_v = robot.random.uniform(0,MAX_VELOCITY)
  local right_v = robot.random.uniform(0,MAX_VELOCITY)
  
  -- States: each direction can be 0 or 1, a state is a combination of those.
  -- So in total the states are 2^8 = 256.
  sensor_direction_names = {"N", "NW", "W", "SW", "S", "SE", "E", "NE"}
  number_of_states = math.pow(2, #sensor_direction_names)
  
  -- Actions: 3 in total
  velocity_direction_names = {"WNW", "N", "ENE"}
  velocity_directions = {
    ["WNW"] = math.pi / 4, -- 45 degree
    ["N"] = 0,
    ["ENE"] = - math.pi / 4, -- -45 degree
  }
  
  
  number_of_actions = #velocity_direction_names
  
  Q_table = {}
  
  -- Dimension: 256 x 3 = 768 values.
  Q_table = Qlearning.load_Q_table(FILENAME)
  
	robot.wheels.set_velocity(left_v,right_v)
  
end

-- Random walk when is in white state
function competence0()
  local choice = robot.random.uniform(0, 1)
  local left_v = robot.wheels.velocity_left
  local right_v = robot.wheels.velocity_right

  if choice < 0.2 then -- Move left 20%
    left_v = MAX_VELOCITY
    right_v = MAX_VELOCITY / 2
  elseif choice >= 0.2 and choice < 0.4 then -- Move right 20%
     left_v = MAX_VELOCITY / 2
     right_v = MAX_VELOCITY 
  elseif choice >= 0.4 and choice < 0.5 then -- Move more right 10%
     left_v = MAX_VELOCITY / 4
     right_v = MAX_VELOCITY 
  elseif choice >= 0.5 and choice < 0.6 then -- Move more left 10%
     left_v = MAX_VELOCITY 
     right_v = MAX_VELOCITY / 4
  end
  -- 40% continue to go where it is going

  return left_v, right_v
end

-- Follow the circuit 
function competence1()

  ---------------------
  -- Inner functions --
  ---------------------
  function action_to_velocity(action)

    -- Ensure not to exceed MAX_VELOCITY
    function limit_v(left_v, right_v)

      function limit(value)
        if (value > MAX_VELOCITY) then
          value = MAX_VELOCITY
        end
        
        if (value < - MAX_VELOCITY) then
          value = - MAX_VELOCITY
        end

        return value
      end
      
      return limit(left_v), limit(right_v)

    end
    
    local angle = velocity_directions[velocity_direction_names[action]]
    local left_v = MAX_VELOCITY - (angle * WHEEL_DIST / 2)
    local right_v = MAX_VELOCITY + (angle * WHEEL_DIST / 2)
    
    left_v, right_v = limit_v(left_v, right_v)
    
    return left_v, right_v
    
  end

  function get_state()
    -- State goes from 1 to 256.
    -- 1 equals that all sensors are 0.
    local new_state = 1
    
    for i = 1, #robot.base_ground do
      if robot.base_ground[i].value == 1 then 
        new_state = new_state + math.pow(2,i-1) 
      end
    end
    
    return new_state
    
  end

  local state = get_state()
  local action = Qlearning.get_best_action(state, Q_table)
  local subsumption = true
  
  total_state_acquisition = total_state_acquisition + 1

  if state == number_of_states then -- erntirely on white part, move random se lo stato è nero 1== 256 non entra
    subsumption = false
    on_white_circuit_acquisition = on_white_circuit_acquisition + 1
  end
  
  return subsumption, action_to_velocity(action)

end


--- This function is executed at each time step.
-- It must contain the logic of your controller.
function step()
	n_steps = n_steps + 1
  
  -- Perform action
  if n_steps % MOVE_STEPS == 0 then
  
    left_v0_random, right_v0_random = competence0()
    subsumption1, left_v1_action, right_v1_action = competence1()
    
    if (subsumption1) then --- Is minimum one of the sensors black?
      robot.wheels.set_velocity(left_v1_action, right_v1_action)
    else --- if state is  ==256 all sensors are on the white area -> move random
      robot.wheels.set_velocity(left_v0_random, right_v0_random)
    end

	end
 
end

--[[ This function is executed every time you press the 'reset'
     button in the GUI. It is supposed to restore the state
     of the controller to whatever it was right after init() was
     called. The state of sensors and actuators is reset
     automatically by ARGoS. ]]
function reset()
	local left_v = 0
	local right_v = 0
	robot.wheels.set_velocity(left_v,right_v)
	n_steps = 0
end



--[[ This function is executed only once, when the robot is removed
     from the simulation ]]
function destroy()
   -- put your code here

   metric = math.floor((on_white_circuit_acquisition/total_state_acquisition) * 10000) / 10000

   --[[file = io.open("markers-test.txt", "a")

   file:write(metric .. "\n")

   file:close() ]]
   print(metric .. ", !!marker!!")
end
