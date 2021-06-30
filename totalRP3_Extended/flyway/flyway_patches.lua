----------------------------------------------------------------------------------
-- Total RP 3: Extended
-- Schema migration tool : Patches
--	---------------------------------------------------------------------------
--	Copyright 2014 Sylvain Cossement (telkostrasz@telkostrasz.be)
--	          2018 Paul Corlay (paul.corlay@gmail.com)
--
--	Licensed under the Apache License, Version 2.0 (the "License");
--	you may not use this file except in compliance with the License.
--	You may obtain a copy of the License at
--
--		http://www.apache.org/licenses/LICENSE-2.0
--
--	Unless required by applicable law or agreed to in writing, software
--	distributed under the License is distributed on an "AS IS" BASIS,
--	WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
--	See the License for the specific language governing permissions and
--	limitations under the License.
----------------------------------------------------------------------------------

TRP3_API.extended.flyway.patches = {};

local pairs, tremove = pairs, tremove;

-- Converting stash/drop mapID to uiMapID (for 8.0)
TRP3_API.extended.flyway.patches["1"] = function()
    local UIMAPID_CONVERSION_TABLE = { {1,4},
        {7,9},
        {10,11},
        {12,13},
        {13,14},
        {14,16},
        {15,17},
        {17,19},
        {18,20},
        {21,21},
        {22,22},
        {23,23},
        {25,24},
        {26,26},
        {27,27},
        {32,28},
        {36,29},
        {37,30},
        {42,32},
        {47,34},
        {48,35},
        {49,36},
        {50,37},
        {51,38},
        {52,39},
        {56,40},
        {57,41},
        {62,42},
        {63,43},
        {64,61},
        {65,81},
        {66,101},
        {69,121},
        {70,141},
        {71,161},
        {76,181},
        {77,182},
        {78,201},
        {80,241},
        {81,261},
        {83,281},
        {84,301},
        {85,321},
        {87,341},
        {88,362},
        {89,381},
        {90,382},
        {91,401},
        {92,443},
        {93,461},
        {94,462},
        {95,463},
        {97,464},
        {100,465},
        {101,466},
        {102,467},
        {103,471},
        {104,473},
        {105,475},
        {106,476},
        {107,477},
        {108,478},
        {109,479},
        {110,480},
        {111,481},
        {112,482},
        {113,485},
        {114,486},
        {115,488},
        {116,490},
        {117,491},
        {118,492},
        {119,493},
        {120,495},
        {121,496},
        {122,499},
        {123,501},
        {124,502},
        {127,510},
        {128,512},
        {130,521},
        {142,528},
        {147,529},
        {153,530},
        {155,531},
        {169,540},
        {170,541},
        {174,544},
        {179,545},
        {184,602},
        {194,605},
        {198,606},
        {199,607},
        {200,609},
        {201,610},
        {202,611},
        {203,613},
        {204,614},
        {205,615},
        {206,626},
        {207,640},
        {210,673},
        {217,684},
        {218,685},
        {219,686},
        {224,689},
        {233,697},
        {234,699},
        {241,700},
        {244,708},
        {245,709},
        {247,717},
        {249,720},
        {273,733},
        {274,734},
        {275,736},
        {276,737},
        {277,747},
        {327,772},
        {329,775},
        {333,781},
        {335,789},
        {337,793},
        {338,795},
        {339,796},
        {367,800},
        {371,806},
        {376,807},
        {378,808},
        {379,809},
        {388,810},
        {390,811},
        {397,813},
        {398,816},
        {399,819},
        {401,820},
        {407,823},
        {409,824},
        {416,851},
        {417,856},
        {418,857},
        {422,858},
        {424,862},
        {425,864},
        {427,866},
        {433,873},
        {443,877},
        {447,878},
        {448,880},
        {449,881},
        {450,882},
        {451,883},
        {452,884},
        {456,886},
        {457,887},
        {460,888},
        {461,889},
        {462,890},
        {463,891},
        {465,892},
        {467,893},
        {468,894},
        {469,895},
        {483,906},
        {486,911},
        {487,912},
        {488,914},
        {490,919},
        {498,920},
        {504,928},
        {507,929},
        {516,933},
        {519,935},
        {520,937},
        {523,939},
        {524,940},
        {525,941},
        {534,945},
        {535,946},
        {539,947},
        {542,948},
        {543,949},
        {550,950},
        {554,951},
        {556,953},
        {571,955},
        {572,962},
        {577,970},
        {582,973},
        {588,978},
        {590,980},
        {592,983},
        {594,986},
        {610,994},
        {619,1007},
        {620,1008},
        {622,1009},
        {623,1010},
        {624,1011},
        {625,1014},
        {630,1015},
        {634,1017},
        {641,1018},
        {645,1020},
        {646,1021},
        {649,1022},
        {650,1024},
        {661,1026},
        {671,1027},
        {672,1028},
        {676,1031},
        {680,1033},
        {694,1034},
        {696,1037},
        {697,1038},
        {703,1041},
        {706,1042},
        {709,1044},
        {713,1046},
        {714,1047},
        {715,1048},
        {717,1050},
        {718,1051},
        {719,1052},
        {725,1056},
        {726,1057},
        {728,1059},
        {731,1065},
        {733,1067},
        {738,1071},
        {739,1072},
        {747,1077},
        {748,1078},
        {750,1080},
        {757,1082},
        {758,1084},
        {760,1086},
        {761,1087},
        {773,1090},
        {775,1091},
        {776,1092},
        {790,1096},
        {793,1099},
        {799,1104},
        {806,1114},
        {823,1116},
        {824,1126},
        {830,1135},
        {834,1136},
        {837,1139},
        {838,1140},
        {843,1144},
        {844,1145},
        {858,1149},
        {859,1150},
        {860,1151},
        {861,1152},
        {862,1153},
        {863,1154},
        {864,1155},
        {871,1160},
        {872,1161},
        {875,1162},
        {876,1163},
        {877,1164},
        {878,1165},
        {882,1170},
        {885,1171},
        {891,1174},
        {895,1175},
        {896,1176},
        {897,1177},
        {903,1178},
        {904,1183},
        {905,1184},
        {906,1185},
        {907,1186},
        {908,1187},
        {909,1188},
        {921,1190},
        {922,1191},
        {923,1192},
        {924,1193},
        {925,1194},
        {926,1195},
        {927,1196},
        {928,1197},
        {929,1198},
        {930,1199},
        {931,1200},
        {932,1201},
        {933,1202},
        {936,1205},
        {938,1210},
        {939,1211},
        {942,1213},
        {943,1214},
        {971,1215},
        {972,1216},
        {974,1219},
        {981,1220},
        {994,1184} };

    local function getUiMapID(mapID)
        for _, IDPair in pairs(UIMAPID_CONVERSION_TABLE) do
            if IDPair[2] == mapID then
                return IDPair[1];
            end
        end
    end

    if TRP3_Drop then
        for realmID, realmTab in pairs(TRP3_Drop) do
            for dropID, drop in pairs(realmTab) do
                if drop.mapID then
                    local uiMapID = getUiMapID(drop.mapID);
                    if uiMapID then
                        drop.uiMapID = uiMapID;
                        drop.mapID = nil;
                    else
                        tremove(TRP3_Drop[realmID], dropID);
                    end
                end
            end
        end
    end

    if TRP3_Stashes then
        for realmID, realmTab in pairs(TRP3_Stashes) do
            for stashID, stash in pairs(realmTab) do
                if stash.mapID then
                    local uiMapID = getUiMapID(stash.mapID);
                    if uiMapID then
                        stash.uiMapID = uiMapID;
                        stash.mapID = nil;
                    else
                        tremove(TRP3_Stashes[realmID], stashID);
                    end
                end
            end
        end
    end
end

-- Fixing wrong array key for drops in 1.2.0
TRP3_API.extended.flyway.patches["2"] = function()
    if TRP3_Drop then
        for _, realmTab in pairs(TRP3_Drop) do
            for _, drop in pairs(realmTab) do
                if drop.mapID then
                    drop.uiMapID = drop.mapID;
                    drop.mapID = nil;
                end
            end
        end
    end
end