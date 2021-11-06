<?xml version="1.0" encoding="UTF-8"?>
<tileset version="1.5" tiledversion="1.7.2" name="pixel_platformer" tilewidth="18" tileheight="18" tilecount="260" columns="20">
 <image source="../textures/tilesets/pixel_platformer.png" width="360" height="234"/>
 <tile id="0">
  <objectgroup draworder="index" id="2">
   <object id="1" x="0" y="0" width="18" height="18"/>
  </objectgroup>
 </tile>
 <tile id="153">
  <objectgroup draworder="index" id="2">
   <object id="1" type="one_way" x="0" y="0" width="18" height="8"/>
  </objectgroup>
 </tile>
 <tile id="154">
  <objectgroup draworder="index" id="2">
   <object id="1" type="one_way" x="0" y="0" width="18" height="8"/>
  </objectgroup>
 </tile>
 <tile id="155">
  <objectgroup draworder="index" id="2">
   <object id="1" type="one_way" x="0" y="0" width="18" height="8"/>
  </objectgroup>
 </tile>
 <wangsets>
  <wangset name="ground" type="corner" tile="22">
   <wangcolor name="grass" color="#ff0000" tile="22" probability="1"/>
   <wangtile tileid="4" wangid="0,1,0,0,0,1,0,1"/>
   <wangtile tileid="5" wangid="0,1,0,1,0,0,0,1"/>
   <wangtile tileid="21" wangid="0,0,0,1,0,0,0,0"/>
   <wangtile tileid="22" wangid="0,0,0,1,0,1,0,0"/>
   <wangtile tileid="23" wangid="0,0,0,0,0,1,0,0"/>
   <wangtile tileid="24" wangid="0,0,0,1,0,1,0,1"/>
   <wangtile tileid="25" wangid="0,1,0,1,0,1,0,0"/>
   <wangtile tileid="121" wangid="0,1,0,1,0,0,0,0"/>
   <wangtile tileid="122" wangid="0,1,0,1,0,1,0,1"/>
   <wangtile tileid="123" wangid="0,0,0,0,0,1,0,1"/>
   <wangtile tileid="141" wangid="0,1,0,0,0,0,0,0"/>
   <wangtile tileid="142" wangid="0,1,0,0,0,0,0,1"/>
   <wangtile tileid="143" wangid="0,0,0,0,0,0,0,1"/>
  </wangset>
  <wangset name="shroom platform" type="edge" tile="13">
   <wangcolor name="shroom" color="#ff0000" tile="-1" probability="1"/>
   <wangtile tileid="12" wangid="0,0,1,0,1,0,1,0"/>
   <wangtile tileid="13" wangid="0,0,1,0,0,0,1,0"/>
   <wangtile tileid="14" wangid="0,0,1,0,0,0,0,0"/>
   <wangtile tileid="15" wangid="0,0,0,0,0,0,1,0"/>
   <wangtile tileid="32" wangid="1,0,0,0,1,0,0,0"/>
   <wangtile tileid="52" wangid="1,0,0,0,1,0,0,0"/>
   <wangtile tileid="72" wangid="1,0,0,0,0,0,0,0"/>
  </wangset>
  <wangset name="pipes" type="edge" tile="180">
   <wangcolor name="pipes" color="#ff0000" tile="-1" probability="1"/>
   <wangtile tileid="180" wangid="0,0,0,0,1,0,0,0"/>
   <wangtile tileid="181" wangid="0,0,1,0,1,0,0,0"/>
   <wangtile tileid="182" wangid="0,0,1,0,0,0,1,0"/>
   <wangtile tileid="183" wangid="0,0,0,0,0,0,1,0"/>
   <wangtile tileid="200" wangid="1,0,0,0,1,0,0,0"/>
   <wangtile tileid="201" wangid="1,0,1,0,1,0,0,0"/>
   <wangtile tileid="202" wangid="0,0,1,0,1,0,1,0"/>
   <wangtile tileid="203" wangid="0,0,0,0,1,0,1,0"/>
   <wangtile tileid="220" wangid="1,0,1,0,0,0,0,0"/>
   <wangtile tileid="221" wangid="1,0,1,0,1,0,1,0"/>
   <wangtile tileid="222" wangid="1,0,1,0,0,0,1,0"/>
   <wangtile tileid="223" wangid="1,0,0,0,1,0,1,0"/>
   <wangtile tileid="241" wangid="1,0,0,0,0,0,0,0"/>
   <wangtile tileid="242" wangid="0,0,1,0,0,0,0,0"/>
   <wangtile tileid="243" wangid="1,0,0,0,0,0,1,0"/>
  </wangset>
 </wangsets>
</tileset>
