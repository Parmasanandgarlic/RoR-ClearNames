<?xml version="1.0" encoding="UTF-8"?>
<ModuleFile xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <UiMod name="ClearNames" version="0.2.1" date="09/09/2026">
    <Author name="ClearNames contributors" />
    <Description text="Readability-first overhead-name and UI font optimizer for Return of Reckoning." />
    <VersionSettings gameVersion="1.4.8" windowsVersion="1.0" savedVariablesVersion="1.0" />
    <Dependencies>
      <Dependency name="EASystem_Utils" />
      <Dependency name="EASystem_TargetInfo" />
      <Dependency name="EATemplate_DefaultWindowSkin" />
      <Dependency name="LibSlash" optional="true" />
    </Dependencies>
    <Files>
      <File name="Fonts.lua" />
      <File name="NativeRenderer.lua" />
      <File name="Profiles.lua" />
      <File name="FontLab.lua" />
      <File name="HDLabels.lua" />
      <File name="UIFonts.lua" />
      <File name="ClearNames.lua" />
      <File name="ClearNames.xml" />
    </Files>
    <OnInitialize><CallFunction name="ClearNames.OnInitialize" /></OnInitialize>
    <OnShutdown><CallFunction name="ClearNames.OnShutdown" /></OnShutdown>
    <SavedVariables>
      <SavedVariable name="ClearNames.Settings" global="false" />
      <SavedVariable name="ClearNames.FontScores" global="false" />
    </SavedVariables>
  </UiMod>
</ModuleFile>
