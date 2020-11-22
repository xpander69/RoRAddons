<?xml version="1.0" encoding="UTF-8"?>
<ModuleFile xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <UiMod name="TargetInfoRing" version="0.9.0" date="2019-01-18">
    <VersionSettings gameVersion="1.4.8" windowsVersion="1.0" savedVariablesVersion="1.0" />
    <Author name="cupnoodles; original author:Talvinen" email="cupn8dles@gmail.com; redefiance@gmx.de" />
    <!-- <Author name="Talvinen" email="redefiance@gmx.de" /> -->
    <Description text="Show a ring around your target. Now with target info too!" />
    <Dependencies>
    </Dependencies>
    <Files>
      <File name="targetinforing.xml" />
      <File name="targetinforing.lua" />
    </Files>
    <OnInitialize>
      <CallFunction name="TargetInfoRing.Initialize" />
    </OnInitialize>
  </UiMod>
</ModuleFile>
