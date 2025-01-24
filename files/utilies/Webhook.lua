local Services = loadstring(game:HttpGet("https://raw.githubusercontent.com/fourjet4z/foundation/refs/heads/main/files/utilies/Services.lua"))();



local HttpService = Services:Get("HttpService");

local Webhook = {};
Webhook.__index = Webhook;

local httprequest = (syn and syn.request) or http and http.request or http_request or (fluxus and fluxus.request) or request;

function Webhook.SichNew(url)
    assert(typeof(url) == "string" and url ~= "", "Invalid URL provided");
    return setmetatable({
        _url = url;
    }, Webhook);
end;

function Webhook:Send(ping, payload, yields)
    if (payload) then
        if (typeof(payload) == "string") then
            payload = {content = payload};
        elseif (typeof(payload) == "table" and not payload.content) then
            payload.content = "";
        end;
    else
        payload = {content = ""};
    end;

    if (ping and typeof(ping) == "string") then
        payload.content = ping.." "..payload.content;
    end;

    local function send()
        local succ, response = pcall(function()
            local encodedPayload = HttpService:JSONEncode(payload);
            if (httprequest) then
                return httprequest({
                    Url = self._url,
                    Method = "POST",
                    Headers = {
                        ["Content-Type"] = "application/json"
                    },
                    Body = encodedPayload
                });
            else
                return HttpService:PostAsync(self._url, encodedPayload, Enum.HttpContentType.ApplicationJson);
            end;
        end);
        return succ, response;
    end;

    if (yields) then
        return send();
    else
        task.spawn(send);
    end;
end;

return Webhook;
