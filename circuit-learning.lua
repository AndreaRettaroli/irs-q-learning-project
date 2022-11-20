-- Global variables

MOVE_STEPS = 5 --make decisions every 5 step
MAX_VELOCITY = 5 --velocity 
FILENAME = "Qtable-circuit.csv" --q table file name
WHEEL_DIST = -1  -- distance between wheels

n_steps = 0 -- counter
sum_rewards = 0 --sum of reward 
count = 0 -- counter

--- This function is executed every time you press the 'execute' button.
function init()

  Qlearning = require "Qlearning"
	
	WHEEL_DIST = robot.wheels.axis_length

  total_state_acquisition = 0 -- total number of times that the robot is on the black and the white part of arena
  on_white_circuit_acquisition = 0 --- numeber of times that the robot is in correct part of arena, the white part
  
  --- First action is to go forward.
  --- If the velocity is equal velocità on left and right robot go straight,
  --- if  Left>Right robot go left
  --- If Right>Left robot go right
	local left_v = MAX_VELOCITY
	local right_v = MAX_VELOCITY

--- Hyperparameters for q learning

  --- learning rate: more alpha is high less the robot remembers, more alpha is low more it remembers
  alpha = 0.1 
  --- the discount factor: it goes from 0 to 1, indicate how much do you want to maximize rewards going forward or in the future?
  gamma = 0.9 
  --- epsilon the probability of peeking a random action, it must be from 0 (never random) to 1 (always random).
  epsilon = 0.9 --never used
  --- k how strong the selection favours actions with high Q table value, must be grater or equal to 1.
  k = 2
  
  old_state = get_state() ---the current robot state
  state = old_state
  action = 1
  
  -- States: each direction can be 0 or 1, a state is a combination of those.
  -- So in total the states are 2^8 = 256.
  sensor_direction_names = {"N", "NW", "W", "SW", "S", "SE", "E", "NE"}
  number_of_states = math.pow(2, #sensor_direction_names)
  
  -- Actions: are 3 in total
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

function get_state()
  -- State goes from 1 to 256.
  -- 1 equals that all sensors are 0.
  local new_state = 1
  
  for i = 1, #robot.base_ground do
    -- if the values of base ground is equals to 1 there is white area under the robot
    if robot.base_ground[i].value == 1 then 
      new_state = new_state + math.pow(2,i-1) 
    end
  end
  
  return new_state
end

function get_reward()
  -- Rewards goes from 0 to 1
  local white_sensors = 0
  
  for i = 1, #robot.base_ground do
    if robot.base_ground[i].value == 1 then 
      white_sensors = white_sensors + 1 
    end
  end

  return math.pow(white_sensors / #robot.base_ground, 2) -- rw=(number of sensor in white area / total sensor)^2

end
--next action to do
function perform_action(action)
  
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
  
  robot.wheels.set_velocity(left_v,right_v)
  
end

--- This function is executed at each time step.
-- It must contain the logic of your controller.
function step()
	n_steps = n_steps + 1
  -- update counter of total state 2 times per seconds
	if n_steps % MOVE_STEPS == 0 then
    total_state_acquisition = total_state_acquisition + 1

    -- Update
    state = get_state()
    -- update counter if the robot completely is in white area
    if old_state ~= 1 then
      on_white_circuit_acquisition = on_white_circuit_acquisition + 1
    end

    local reward = get_reward()

    Q_table = Qlearning.update_Q_table(alpha, gamma, old_state, action, reward, state, Q_table)

    sum_rewards = sum_rewards + reward
    count = count + 1


    -- Perform the best action and update state
    -- action = Qlearning.get_random_action(epsilon, state, Q_table)
    action = Qlearning.get_weighted_action(k, old_state, Q_table)
    perform_action(action)
    old_state = state

  end
 
end


--[[ This function is executed every time you press the 'reset'
     button in the GUI. It is supposed to restore the state
     of the controller to whatever it was right after init() was
     called. The state of sensors and actuators is reset
     automatically by ARGoS. ]]
function reset()
	local left_v = MAX_VELOCITY
	local right_v = MAX_VELOCITY
  action = 1
	robot.wheels.set_velocity(left_v,right_v)
	n_steps = 0
end


--[[ This function is executed only once, when the robot is removed
     from the simulation ]]
function destroy()
   -- put your code here
   Qlearning.save_Q_table(FILENAME, Q_table)

   metric = math.floor((on_white_circuit_acquisition/total_state_acquisition) * 10000) / 10000
   -- print(metric .. ", !!marker!!")

   file = io.open("results/average_reward_noise.txt", "a")

   file:write(sum_rewards / count.."\n")

   file:close()
   
end
