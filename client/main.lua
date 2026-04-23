-- [[ TMG MAINFRAME: MINIGAME STATE MATRIX ]]
-- Unified registry for active promises and game-specific variables
MinigameState = {
    activePromises = {}, -- Stores active game promises by type
    quizRequired = 0     -- Shared variable for quiz thresholds
}

-- [[ TMG UTILITIES: KINETIC HELPERS ]]

local function ResolveGame(type, result, focusReset)
    if not MinigameState.activePromises[type] then return end
    
    if focusReset then SetNuiFocus(false, false) end
    MinigameState.activePromises[type]:resolve(result)
    MinigameState.activePromises[type] = nil
    
    print("^5[TMG]^7 Minigame instance resolved: " .. type)
end

-- [[ TMG INTERFACE: NUI CALLBACKS ]]

-- 1. Word Scramble Logic
RegisterNUICallback('scrambleIncorrect', function(_, cb)
    TriggerEvent('QBCore:Notify', 'Incorrect word', 'error', 2500)
    cb('ok')
end)

RegisterNUICallback('scrambleCorrect', function(_, cb)
    TriggerEvent('QBCore:Notify', 'Guessed correctly!', 'success', 2500)
    SendNUIMessage({ action = 'close' })
    ResolveGame('wordScramble', true, true)
    cb('ok')
end)

RegisterNUICallback('scrambleTimeOut', function(_, cb)
    SendNUIMessage({ action = 'close' })
    ResolveGame('wordScramble', false, true)
    cb('ok')
end)

RegisterNUICallback('closeScramble', function(_, cb)
    SendNUIMessage({ action = 'close' })
    ResolveGame('wordScramble', false, true)
    cb('ok')
end)

-- 2. Hacking Logic
RegisterNuiCallback('hackSuccess', function(_, cb) ResolveGame('hacking', true, true) cb('ok') end)
RegisterNuiCallback('hackFail', function(_, cb) ResolveGame('hacking', false, true) cb('ok') end)
RegisterNuiCallback('hackClosed', function(_, cb) ResolveGame('hacking', false, true) cb('ok') end)

-- 3. Key Minigame Logic
RegisterNuiCallback('keyminigameExit', function(_, cb) ResolveGame('keyminigame', { quit = true, faults = 0 }, true) cb('ok') end)
RegisterNuiCallback('keyminigameFinish', function(data, cb) ResolveGame('keyminigame', { quit = false, faults = data.faults }, true) cb('ok') end)

-- 4. Lockpick Logic
RegisterNuiCallback('lockpickExit', function(_, cb) ResolveGame('lockpick', false, true) cb('ok') end)
RegisterNuiCallback('lockpickFinish', function(data, cb) ResolveGame('lockpick', data.success, true) cb('ok') end)

-- 5. Pinpad Logic
RegisterNUICallback('pinpadExit', function(_, cb) ResolveGame('pinpad', { quit = true }, true) cb('ok') end)
RegisterNUICallback('pinpadFinish', function(data, cb) ResolveGame('pinpad', { quit = false, correct = data.correct }, true) cb('ok') end)

-- 6. Quiz Logic
RegisterNUICallback('exitQuiz', function(_, cb) 
    MinigameState.quizRequired = 0
    ResolveGame('quiz', false, true) 
    cb('ok') 
end)

RegisterNUICallback('quitQuiz', function(data, cb)
    local success = data.score >= MinigameState.quizRequired
    MinigameState.quizRequired = 0
    ResolveGame('quiz', success, true)
    cb('ok')
end)

-- 7. Skillbar Logic
RegisterNUICallback('skillbarFinish', function(data, cb) ResolveGame('skillbar', data.success, true) cb('ok') end)

-- 8. Word Guess Logic
RegisterNUICallback('wordGuessedCorrectly', function(_, cb) 
    SendNUIMessage({ action = 'closeWordGuess' })
    ResolveGame('wordGuess', true, true) 
    cb('ok') 
end)

RegisterNUICallback('tooManyGuesses', function(_, cb) 
    SendNUIMessage({ action = 'closeWordGuess' })
    ResolveGame('wordGuess', false, true) 
    cb('ok') 
end)

RegisterNUICallback('closeWordGuess', function(_, cb) 
    SendNUIMessage({ action = 'closeWordGuess' })
    ResolveGame('wordGuess', false, true) 
    cb('ok') 
end)

-- [[ TMG INTERFACE ENGINE: CORE EXPORTS ]]

-- Word Scramble
exports('WordScramble', function(word, hint, timer)
    MinigameState.activePromises['wordScramble'] = promise.new()
    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'wordScramble', word = word, hint = hint, time = timer })
    print("^5[TMG]^7 Word Scramble initiated. Goal: " .. word)
    return Citizen.Await(MinigameState.activePromises['wordScramble'])
end)

-- Hacking
exports('Hacking', function(solutionsize, timeout)
    MinigameState.activePromises['hacking'] = promise.new()
    SetNuiFocus(true, false)
    SendNUIMessage({ action = 'startHack', solutionsize = solutionsize, timeout = timeout })
    print("^5[TMG]^7 Hacking sequence engaged. Matrix size: " .. solutionsize)
    return Citizen.Await(MinigameState.activePromises['hacking'])
end)

-- Key Minigame
exports('KeyMinigame', function(amount)
    MinigameState.activePromises['keyminigame'] = promise.new()
    SetNuiFocus(true, false)
    SendNUIMessage({ action = 'startKeygame', amount = amount })
    print("^5[TMG]^7 Key sequence initiated. Sequence length: " .. amount)
    return Citizen.Await(MinigameState.activePromises['keyminigame'])
end)

-- Lockpick
exports('Lockpick', function(pins)
    MinigameState.activePromises['lockpick'] = promise.new()
    SetNuiFocus(true, true)
    SetCursorLocation(0.5, 0.5)
    SendNUIMessage({ action = 'startLockpick', pins = pins })
    print("^5[TMG]^7 Lock manipulation sequence active. Pins: " .. pins)
    return Citizen.Await(MinigameState.activePromises['lockpick'])
end)

-- Pinpad
exports('StartPinpad', function(numbers)
    MinigameState.activePromises['pinpad'] = promise.new()
    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'openPinpad', numbers = numbers })
    print("^5[TMG]^7 Pinpad authorization node active.")
    return Citizen.Await(MinigameState.activePromises['pinpad'])
end)

-- Quiz
exports('Quiz', function(questions, correctRequired, timer)
    for i, question in ipairs(questions) do question.numb = i end
    MinigameState.quizRequired = correctRequired
    MinigameState.activePromises['quiz'] = promise.new()
    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'startQuiz', questions = questions, timer = timer })
    print("^5[TMG]^7 Cognitive evaluation engaged. Required score: " .. correctRequired)
    return Citizen.Await(MinigameState.activePromises['quiz'])
end)

-- Skillbar
exports('Skillbar', function(difficulty, validKeys)
    MinigameState.activePromises['skillbar'] = promise.new()
    SetNuiFocus(true, false)
    SendNUIMessage({ action = 'openSkillbar', difficulty = difficulty or 'easy', validKeys = validKeys or '1234' })
    print("^5[TMG]^7 Skillbar synchronization active. Level: " .. (difficulty or 'easy'))
    return Citizen.Await(MinigameState.activePromises['skillbar'])
end)

-- Word Guess
exports('WordGuess', function(word, hint, guesses)
    MinigameState.activePromises['wordGuess'] = promise.new()
    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'wordGuess', word = word, hint = hint, maxGuesses = guesses })
    print("^5[TMG]^7 Word Guess algorithm active. Max attempts: " .. guesses)
    return Citizen.Await(MinigameState.activePromises['wordGuess'])
end)