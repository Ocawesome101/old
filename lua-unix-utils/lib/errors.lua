local errors = {}

function errors.error(err)
  printError(err)
end

function errors.noSuchFile(file)
  errors.error((file or "file") .. ": no such file or directory")
end

return errors
