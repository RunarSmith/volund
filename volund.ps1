$ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Definition

# PowerShell 5 has some known limitations with unloading types, classes, and definitions, especially when you define them in a session and then try to reload or redefine them. This is because:

# Types and classes are loaded into the AppDomain: Once a type or class is loaded, PowerShell 5 (which runs on .NET Framework) cannot unload individual types or classes without unloading the entire AppDomain. PowerShell sessions don’t create new AppDomains for each script, so types persist for the life of the session.

# Workarounds: The only way to “free” or reload types is to start a new session (restart PowerShell or use a new runspace).

# Why does this happen? This is a limitation of the .NET Framework, not just PowerShell. .NET Core (used in PowerShell 7+) improves this a bit, but still doesn’t allow unloading individual types—only entire assemblies via unloading an AssemblyLoadContext.

powershell -NoProfile -ExecutionPolicy Bypass -File "$ScriptRoot/volundlib.ps1" @args
