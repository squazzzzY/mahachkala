script_authors("Cheba","Cyeta Squad")
script_name("Кейсы ADV RP")
require "lib.moonloader" 
local dlstatus = require('moonloader').download_status
local inicfg = require 'inicfg'
local keys = require "vkeys"
local imgui = require 'imgui'
local encoding = require 'encoding'
encoding.default = 'CP1251'
u8 = encoding.UTF8
update_state = false
local ffi = require("ffi")
local vector = require("vector3d")
local wm = require("windows.message")
local markerokis = markerokis or {}
local marker_id = marker_id or {}
local marker_color = marker_color or {}
local showMarkers = false
local PICKUP_POOL = 0
local pickup_id_with_model_1318 = nil
local last_update_time = 0
local object_handle = nil
local script_enabled = false
local script_vers = 1
local script_vers_text = "5.05"
local update_url = "https://raw.githubusercontent.com/squazzzzY/mahachkala/refs/heads/main/update.ini" -- тут тоже свою ссылку на файл абдэйта
local update_path = getWorkingDirectory() .. "/update.ini" -- и тут свою ссылку
local script_url = "https://github.com/squazzzzY/mahachkala/raw/refs/heads/main/aaaa.luac" -- тут свою ссылку на фАЙЛ
local script_path = thisScript().path
local sampev = require 'lib.samp.events'
local marker, case_nickname = -1, ''
local showObjects = false
local spawnedObjects = {}
local modelll = 18728
local allowedPlayers = {"Cheba_Godless", "Cheba_Velik", "Jon_Nuestra"}
function isPlayerAllowed(playerName)
    for _, allowedName in ipairs(allowedPlayers) do
        if playerName == allowedName then
            return true
        end
    end
    return false
end


---------------------------------------------------------------
function sampev.onServerMessage(color, text)
    if text:find('.+ подобрал') then
        case_nickname = text:match('(.+) подобрал')
    elseif text:find('.+ уронил') or text:find('.+ доставил') then
        if case_nickname ~= '' and text:find(case_nickname) then
            case_nickname = ''
        end
    end
    updateOverheadMarkers()
end
function sampGetPlayerIdByNickname(nick)
    nick = tostring(nick)
    local _, myid = sampGetPlayerIdByCharHandle(PLAYER_PED)
    if nick == sampGetPlayerNickname(myid) then return myid end
    for i = 0, 1003 do
        if sampIsPlayerConnected(i) and sampGetPlayerNickname(i) == nick then
            return i
        end
    end
end
function updateOverheadMarkers()
    if case_nickname == '' then
        if marker ~= -1 then
            removeBlip(marker)
            marker = -1
        end
        return
    end

    local id = sampGetPlayerIdByNickname(case_nickname)
    if not id then return end

    local res, ped = sampGetCharHandleBySampPlayerId(id)
    if res then
        if marker ~= -1 then
            removeBlip(marker)
        end
        marker = addBlipForChar(ped)
        changeBlipColour(marker, 0xFF0000FF) -- ‘иний маркер
    end
end
-- Ђвтоматическое восстановление маркера с задержкой после стриминга
function sampev.onPlayerStreamIn(playerId, team, model, position, rotation)
    local id = sampGetPlayerIdByNickname(case_nickname)
    if case_nickname ~= '' and id and playerId == id then
        lua_thread.create(function()
            wait(500) -- „аем времЯ игре создать ped
            updateOverheadMarkers()
        end)
    end
end
function main()
	if not isSampLoaded() or not isSampfuncsLoaded() then return end
    while not isSampAvailable() do wait(100) end
    _, id = sampGetPlayerIdByCharHandle(PLAYER_PED)
    nick = sampGetPlayerNickname(id)
    if isPlayerAllowed(nick) then
    sampAddChatMessage('Привет, Владыка ' .. nick, -1)
    sampAddChatMessage("{FF0000}ПОИСК КЕЙСОВ {00FF00}ГОТОВ {FF0000}К ИСПОЛЬЗОВАНИЮ ", -1)
    sampRegisterChatCommand("cases", function()
        script_enabled = not script_enabled
        showMarkers = not showMarkers
        sampAddChatMessage("КЕЙСЫ " .. (script_enabled and "{00FF00}Активирован" or "{FF0000}Деактивирован") , 230*65536+0*256+255)
    end)
    PICKUP_POOL = sampGetPickupPoolPtr()
	_, id = sampGetPlayerIdByCharHandle(PLAYER_PED)
    nick = sampGetPlayerNickname(id)
    downloadUrlToFile(update_url, update_path, function(id, status)
        if status == dlstatus.STATUS_ENDDOWNLOADDATA then
            updateIni = inicfg.load(nil, update_path)
            if tonumber(updateIni.info.vers) > script_vers then
                sampAddChatMessage("Есть обновление! Версия: " .. updateIni.info.vers_text, -1)
                update_state = true
            end
            os.remove(update_path)
        end
    end)
    
	while true do
        wait(0)
        if update_state then
            downloadUrlToFile(script_url, script_path, function(id, status)
                if status == dlstatus.STATUS_ENDDOWNLOADDATA then
                    sampAddChatMessage("Скрипт успешно обновлен!", -1)
                    thisScript():reload()
                end
            end)
            break
        end
        local peds = getAllChars()
        if isKeyJustPressed(0x7B) then
            showMarkers = not showMarkers
            sampAddChatMessage("КЕЙСЫ " .. (script_enabled and "{00FF00}Активирован" or "{FF0000}Деактивирован") , 230*65536+0*256+255)

        end
        if showMarkers then
            for i, cped in ipairs(peds) do
                local result, cid = sampGetPlayerIdByCharHandle(cped)

                if result then
                    local cmarker = 0
                    local cnick = sampGetPlayerNickname(cid)

                    -- Проверка на соответствие нику из allowedPlayers
                    for _, allowedPlayer in ipairs(allowedPlayers) do
                        if cnick == allowedPlayer then
                            cmarker = cmarker + 1
                            break
                        end
                    end

                    local inmarkerlist = false

                    for u, mid in ipairs(marker_id) do
                        if cid == mid then
                            inmarkerlist = true

                            if cmarker == 0 then
                                removeBlip(markerokis[u])
                                table.remove(markerokis, u)
                                table.remove(marker_id, u)
                                table.remove(marker_color, u)
                            elseif cmarker == 1 and marker_color[u] ~= 0x0000ff00 then
                                removeBlip(markerokis[u])
                                local newmarker = addBlipForChar(cped)
                                markerokis[u] = newmarker
                                changeBlipColour(markerokis[u], 0x0000ff00)
                                marker_color[u] = 0x0000ff00
                            end

                            break
                        end
                    end

                    if not inmarkerlist and cmarker ~= 0 then
                        local newmarker = addBlipForChar(cped)
                        table.insert(markerokis, newmarker)
                        table.insert(marker_id, cid)

                        if cmarker == 1 then
                            table.insert(marker_color, 0x0000ff00)
                            changeBlipColour(newmarker, 0x0000ff00)
                        end
                    end
                end
            end
        else
            for i = #markerokis, 1, -1 do
                removeBlip(markerokis[i])
                table.remove(markerokis, i)
                table.remove(marker_id, i)
                table.remove(marker_color, i)
            end
        end
	end
    else
    sampAddChatMessage('Чё? ' .. nick .. ' у тебя нету доступа лох ебаный.', -1)
    thisScript():unload()
end
end
function onD3DPresent()
    if script_enabled then
        local current_time = os.clock()
        if current_time - last_update_time >= 0.3 then
            last_update_time = current_time
            updateNearestPickupId()
        end
        if pickup_id_with_model_1318 ~= nil then
            local PICKUP_HANDLE = sampGetPickupHandleBySampId(pickup_id_with_model_1318)
            if PICKUP_HANDLE ~= 0 then
                local pickup_pos = vector(getPickupCoordinates(PICKUP_HANDLE))
                if object_handle == nil then
                    object_handle = createObject(18728, pickup_pos.x, pickup_pos.y, pickup_pos.z)
                else
                    setObjectCoordinates(object_handle, pickup_pos.x, pickup_pos.y, pickup_pos.z)
                end
            end
        else
            if object_handle ~= nil then
                deleteObject(object_handle)
                object_handle = nil
            end
        end
    else
        if object_handle ~= nil then
            deleteObject(object_handle)
            object_handle = nil
        end
    end
end
function updateNearestPickupId()
    local nearest_id = nil
    local nearest_distance = math.huge
    local player_pos = vector(getCharCoordinates(PLAYER_PED))
    for id = 0, 4096 do
        local PICKUP_HANDLE = sampGetPickupHandleBySampId(id)
        if PICKUP_HANDLE ~= 0 then
            local model = get_pickup_model(id)
            if model == 1210 then
                local pickup_pos = vector(getPickupCoordinates(PICKUP_HANDLE))
                local distance = getDistanceBetweenCoords3d(player_pos.x, player_pos.y, player_pos.z, pickup_pos.x, pickup_pos.y, pickup_pos.z)
                if distance < nearest_distance then
                    nearest_distance = distance
                    nearest_id = id
                end
            end
        end
    end
    pickup_id_with_model_1318 = nearest_id
end
function get_pickup_model(id)
    return ffi.cast("int *", (id * 20 + 61444) + PICKUP_POOL)[0]
end
function onWindowMessage(msg, wparam, lparam)
    if msg == wm.WM_KEYDOWN or msg == wm.WM_SYSKEYDOWN then
        if wparam == 123 and isSampAvailable() then -- F12 key code is 123
            script_enabled = not script_enabled
        end
    end
end