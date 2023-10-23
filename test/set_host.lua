core.register_action("set_host_if_backup", { "http-req" }, function(txn)
    local serverId = txn:get_var("req.backend")
    core.Info(serverId)
    if serverId and tonumber(serverId) == 2 then
        txn.http:req_del_header("Host")
        txn.http:req_add_header("Host", "nxp2fsoiuh.execute-api.eu-central-1.amazonaws.com")
    end
end)
