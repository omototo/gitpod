core.register_action("retry_on_non_200", { "http-res" }, function(txn)
    local status = tonumber(txn.sf:status())
    core.Info("Response status: " .. status)

    if status and status ~= 200 then

        txn:set_var("txn.use_backup", "true")
    end
end)