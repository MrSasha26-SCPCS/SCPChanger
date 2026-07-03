local GameObject = CS.UnityEngine.GameObject
local Vector3 = CS.UnityEngine.Vector3

---@class SCPChanger:CS.Akequ.Base.Room
SCPChanger = {}

SCPChanger.time = 60
SCPChanger.isRoundBlocked = false
SCPChanger.isRoundStarted = false

function SCPChanger:Init()
    if self.main.netEvent.isServer then
        local adminPanel = GameObject.FindObjectOfType(typeof(CS.AdminPanel))
        
        CS.HookManager.Add(self.main.netEvent.gameObject, "changeLockRoundState", function(obj)
            self.isRoundBlocked = obj[0]
        end)
        CS.HookManager.Add(self.main.netEvent.gameObject, "onRoundStart", function(obj)
            self.isRoundStarted = true

            if not self.isRoundBlocked then
                local players = GameObject.FindObjectsOfType(typeof(CS.Player))
                for i = 0, players.Length - 1 do
                    local player = players[i]
                    if player ~= nil then
                        local playerClass = player.playerClass
                        if playerClass ~= nil then
                            local classType = playerClass:GetType()
                            if classType ~= nil then
                                local className = classType.Name
                                if className ~= nil then
                                    if string.find(className, "SCP") then
                                        adminPanel:ShowAdminMessage("<size=25><#CCCCCC>Вы можете сменить свой класс на другого SCP с помощью команды <color=white>changescp <color=yellow>[НОМЕР SCP]</color></color></color></size>", 7, player)
                                    end
                                end
                            end
                        end
                    end
                end 
            end
        end)
    end
    if self.main.netEvent.isClient then
        CS.GameConsole.AddCommand("changescp", "позволяет в начале раунда сменить свой класс на другого SCP, если вы стали аномалией", function(obj)
            local scpNumber = obj[0]
            if scpNumber ~= nil then
                local scpClassName = "SCP" .. scpNumber
                self.main:SendToServer("ChangeSCP", scpClassName)
            end
        end)
    end
end

function SCPChanger:Update()
    if self.main.netEvent.isServer and self.time > 0 and self.isRoundStarted then
        self.time = self.time - CS.UnityEngine.Time.deltaTime
    end
end

--CLIENT
function SCPChanger:GetMessage(message)
    CS.GameConsole.PrintConsole("SCPChanger", message, CS.UnityEngine.Color.white)
end

-- SERVER
function SCPChanger:ChangeSCP(scpClassName, conn)
    if self.isRoundBlocked then
        self.main:SendToClient("GetMessage", conn, "<color=red>Раунд заблокирован!</color>")
        return 
    end
        
    local caller = CS.PlayerUtilities.GetServerPlayer(conn)
    if caller ~= nil then    
        local callerClass = caller.playerClass
        if callerClass ~= nil then  
            local callerClassType = callerClass:GetType()
            if callerClassType ~= nil then 
                local callerClassName = callerClassType.Name
                if callerClassName ~= nil then
                    if string.find(callerClassName, "SCP") then
                        if self.time > 0 then
                            if scpClassName == "SCP049" or scpClassName == "SCP079" or
                            scpClassName == "SCP106" or scpClassName == "SCP173" or
                            scpClassName == "SCP939" or scpClassName == "SCP096" or
                            scpClassName == "SCP999" then
                                print("Checking for other scp...")
                                local players = GameObject.FindObjectsOfType(typeof(CS.Player))
                                for i = 0, players.Length - 1 do
                                    local player = players[i]
                                    if player ~= nil then
                                        local playerClass = player.playerClass
                                        if playerClass ~= nil then
                                            local classType = playerClass:GetType()
                                            if classType ~= nil then
                                                local className = classType.Name
                                                if className ~= nil then
                                                    print("Class name got: " .. className)
                                                    if className == scpClassName then
                                                        self.main:SendToClient("GetMessage", conn, "<color=red>Такой SCP уже есть в игре!</color>")
                                                        return
                                                    end
                                                end
                                            end
                                        end
                                    end
                                end
                                caller:SetClass(scpClassName)
                            else
                                self.main:SendToClient("GetMessage", conn, "<color=red>Неверный номер SCP!</color>")
                            end
                        else
                            self.main:SendToClient("GetMessage", conn, "<color=red>С начала раунда прошло слишком много времени!</color>")
                        end
                    else
                        self.main:SendToClient("GetMessage", conn, "<color=red>Вы должны быть SCP, чтобы использовать эту команду!</color>")
                    end
                end
            end
        end
    end
end

return SCPChanger