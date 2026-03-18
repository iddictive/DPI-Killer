import sys
import os

def write_file(name, lines, add_imports=True):
    with open(name, 'w') as f:
        if add_imports:
            f.write("import Cocoa\nimport Foundation\nimport Network\n\n")
        f.writelines(lines)

with open("main.swift", "r") as f:
    lines = f.readlines()

def get_lines(start, end):
    return lines[start-1:end]

write_file("Localization.swift", get_lines(7, 150))
write_file("Models.swift", get_lines(152, 228) + ["\n"] + get_lines(1133, 1136))
write_file("SettingsStore.swift", get_lines(230, 420))
write_file("UpdateManager.swift", get_lines(422, 614))
write_file("SpoofDPIController.swift", get_lines(616, 887))
write_file("NetworkMonitor.swift", get_lines(889, 925))
write_file("SpeedTestManager.swift", get_lines(927, 1083))
write_file("DiagnosticsManager.swift", get_lines(1085, 1131))
write_file("SettingsWindowController.swift", get_lines(1138, 1709))
write_file("SpeedTestWindowController.swift", get_lines(1711, 1813))
write_file("LogWindowController.swift", get_lines(1815, 1898))
write_file("HelpWindowController.swift", get_lines(1900, 1971))
write_file("LoadingWindowController.swift", get_lines(1973, 2010))
write_file("AppDelegate.swift", get_lines(2012, 2204))
write_file("Extensions.swift", get_lines(2216, 2221))

# For main.swift, we only want the imports, the atexit, and the app.run() block
with open("main.swift", "w") as f:
    f.writelines(get_lines(1, 4))
    f.write("\n")
    f.writelines(get_lines(2206, 2214))

print("Successfully splitted main.swift")
