function sys.shutdown()
    log("Logging out " .. users.user())
    users.logout()

    log("Shutting down OS")
end
