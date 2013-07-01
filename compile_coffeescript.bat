cd %~dp0

@IF EXIST "C:/Program Files/nodejs/node.exe" (
  "C:/Program Files/nodejs/node.exe"  "C:/Program Files/nodejs/node_modules/coffee-script/bin/coffee" --output . --compile .
) ELSE (
  node  "C:/Program Files/nodejs/node_modules/coffee-script/bin/coffee" --output . --compile .
)

pause