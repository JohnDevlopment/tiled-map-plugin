<?xml version="1.0" encoding="UTF-8"?>
<tileset version="1.5" tiledversion="1.7.2" name="pixel_platformer" tilewidth="18" tileheight="18" tilecount="260" columns="20">
 <image source="../textures/tilesets/pixel_platformer.png" width="360" height="234"/>
 <tile id="21">
  <objectgroup draworder="index" id="2">
   <object id="1" type="navigation" x="0" y="0" width="18" height="18"/>
   <object id="2" x="0" y="0" width="18" height="18"/>
  </objectgroup>
 </tile>
 <tile id="22">
  <objectgroup draworder="index" id="2">
   <object id="1" type="navigation" x="0" y="0" width="18" height="18"/>
   <object id="2" x="0" y="0" width="18" height="18"/>
  </objectgroup>
 </tile>
 <tile id="23">
  <objectgroup draworder="index" id="2">
   <object id="1" type="navigation" x="0" y="0" width="18" height="18"/>
   <object id="2" x="0" y="0" width="18" height="18"/>
  </objectgroup>
 </tile>
 <tile id="125" probability="0.5"/>
 <tile id="153">
  <objectgroup draworder="index" id="2">
   <object id="2" type="one_way" x="0" y="0">
    <polygon points="0,0 11.625,14.125 17.875,9.5 17.875,-0.5"/>
   </object>
  </objectgroup>
 </tile>
 <tile id="154">
  <objectgroup draworder="index" id="2">
   <object id="1" type="one_way" x="0" y="0">
    <polygon points="0,0 18,0 18,10.875 9.875,16.75 0,11.875"/>
   </object>
  </objectgroup>
 </tile>
 <tile id="182">
  <objectgroup draworder="index" id="2">
   <object id="1" x="0" y="0" width="18" height="18"/>
  </objectgroup>
 </tile>
 <wangsets>
  <wangset name="grass ledge platforms" type="edge" tile="186">
   <wangcolor name="grass" color="#ff0000" tile="186" probability="1"/>
   <wangtile tileid="184" wangid="0,0,0,0,1,0,0,0"/>
   <wangtile tileid="185" wangid="0,0,1,0,1,0,0,0"/>
   <wangtile tileid="186" wangid="0,0,1,0,0,0,1,0"/>
   <wangtile tileid="187" wangid="0,0,0,0,0,0,1,0"/>
   <wangtile tileid="204" wangid="1,0,0,0,1,0,0,0"/>
   <wangtile tileid="205" wangid="1,0,1,0,1,0,0,0"/>
   <wangtile tileid="206" wangid="0,0,1,0,1,0,1,0"/>
   <wangtile tileid="207" wangid="0,0,0,0,1,0,1,0"/>
   <wangtile tileid="224" wangid="1,0,1,0,0,0,0,0"/>
   <wangtile tileid="225" wangid="1,0,1,0,1,0,1,0"/>
   <wangtile tileid="226" wangid="1,0,1,0,0,0,1,0"/>
   <wangtile tileid="227" wangid="1,0,0,0,1,0,1,0"/>
   <wangtile tileid="245" wangid="1,0,0,0,0,0,0,0"/>
   <wangtile tileid="246" wangid="0,0,1,0,0,0,0,0"/>
   <wangtile tileid="247" wangid="1,0,0,0,0,0,1,0"/>
  </wangset>
  <wangset name="grass ledges" type="corner" tile="22">
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
  <wangset name="dead grass ledges" type="corner" tile="62">
   <wangcolor name="dead grass" color="#ff0000" tile="42" probability="1"/>
   <wangtile tileid="4" wangid="0,1,0,0,0,1,0,1"/>
   <wangtile tileid="5" wangid="0,1,0,1,0,0,0,1"/>
   <wangtile tileid="24" wangid="0,0,0,1,0,1,0,1"/>
   <wangtile tileid="25" wangid="0,1,0,1,0,1,0,0"/>
   <wangtile tileid="61" wangid="0,0,0,1,0,0,0,0"/>
   <wangtile tileid="62" wangid="0,0,0,1,0,1,0,0"/>
   <wangtile tileid="63" wangid="0,0,0,0,0,1,0,0"/>
   <wangtile tileid="121" wangid="0,1,0,1,0,0,0,0"/>
   <wangtile tileid="122" wangid="0,1,0,1,0,1,0,1"/>
   <wangtile tileid="123" wangid="0,0,0,0,0,1,0,1"/>
   <wangtile tileid="141" wangid="0,1,0,0,0,0,0,0"/>
   <wangtile tileid="142" wangid="0,1,0,0,0,0,0,1"/>
   <wangtile tileid="143" wangid="0,0,0,0,0,0,0,1"/>
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
  <wangset name="tree top" type="corner" tile="16">
   <wangcolor name="" color="#ff0000" tile="-1" probability="1"/>
   <wangtile tileid="17" wangid="0,0,0,1,0,0,0,0"/>
   <wangtile tileid="18" wangid="0,0,0,1,0,1,0,0"/>
   <wangtile tileid="19" wangid="0,0,0,0,0,1,0,0"/>
   <wangtile tileid="37" wangid="0,1,0,1,0,0,0,0"/>
   <wangtile tileid="38" wangid="0,1,0,1,0,1,0,1"/>
   <wangtile tileid="39" wangid="0,0,0,0,0,1,0,1"/>
   <wangtile tileid="57" wangid="0,1,0,0,0,0,0,0"/>
   <wangtile tileid="58" wangid="0,1,0,0,0,0,0,1"/>
   <wangtile tileid="59" wangid="0,0,0,0,0,0,0,1"/>
  </wangset>
 </wangsets>
</tileset>
