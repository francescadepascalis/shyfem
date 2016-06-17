
from matplotlib.colors import ListedColormap
from numpy import nan, inf

# Used to reconstruct the colormap in pycam02ucs.cm.viscm
parameters = {'xp': [18.524490076703501, 35.696626913667984, 33.753396622295639, 31.767017507653179, 16.32813733033464, 0.0],
              'yp': [5.3490351872871997, 15.614149305555543, 18.922625804010607, 25.874952705259204, 9.917534722222229, 0.0],
              'min_Jp': 15,
              'max_Jp': 95}

cm_data = [[ 0.23605636, 0.03529748, 0.06943744],
           [ 0.24100716, 0.0366455 , 0.07093641],
           [ 0.2459526 , 0.03800641, 0.07241714],
           [ 0.2509034 , 0.03936202, 0.07386826],
           [ 0.25585309, 0.04071754, 0.07529764],
           [ 0.26080496, 0.04203632, 0.07670212],
           [ 0.26576047, 0.04332636, 0.07808053],
           [ 0.2707143 , 0.0445977 , 0.07943946],
           [ 0.27567706, 0.04583263, 0.08076716],
           [ 0.28063775, 0.04705096, 0.08207671],
           [ 0.28560487, 0.04823854, 0.08335867],
           [ 0.29057488, 0.04940214, 0.08461748],
           [ 0.29554566, 0.05054612, 0.085856  ],
           [ 0.30052609, 0.05165528, 0.08706404],
           [ 0.30550643, 0.05274743, 0.08825339],
           [ 0.31049277, 0.0538122 , 0.08941707],
           [ 0.31548518, 0.05484987, 0.09055518],
           [ 0.32047859, 0.05587007, 0.09167406],
           [ 0.32548137, 0.05685797, 0.09276372],
           [ 0.33048827, 0.0578235 , 0.09383067],
           [ 0.33549718, 0.05877098, 0.0948777 ],
           [ 0.34051687, 0.05968444, 0.09589399],
           [ 0.34554046, 0.06057698, 0.09688817],
           [ 0.35056696, 0.06145082, 0.09786159],
           [ 0.35560365, 0.06229245, 0.09880504],
           [ 0.36064578, 0.06311109, 0.09972452],
           [ 0.36569165, 0.06391033, 0.10062225],
           [ 0.37074502, 0.06468313, 0.10149332],
           [ 0.37580723, 0.06542701, 0.10233586],
           [ 0.38087388, 0.06615078, 0.10315552],
           [ 0.38594528, 0.0668541 , 0.10395184],
           [ 0.39102665, 0.06752673, 0.10471769],
           [ 0.39611513, 0.06817445, 0.10545665],
           [ 0.40120891, 0.06880108, 0.10617097],
           [ 0.40630826, 0.0694063 , 0.1068601 ],
           [ 0.41141561, 0.06998523, 0.10752041],
           [ 0.41653225, 0.07053523, 0.10814974],
           [ 0.42165482, 0.07106338, 0.10875243],
           [ 0.42678353, 0.0715694 , 0.10932784],
           [ 0.43191855, 0.07205306, 0.10987533],
           [ 0.43706005, 0.07251411, 0.11039422],
           [ 0.44221111, 0.07294594, 0.11087949],
           [ 0.44736935, 0.07335374, 0.11133402],
           [ 0.45253406, 0.07373915, 0.11175827],
           [ 0.45770533, 0.0741021 , 0.11215148],
           [ 0.46288321, 0.07444262, 0.1125129 ],
           [ 0.4680677 , 0.07476076, 0.11284174],
           [ 0.4732588 , 0.07505667, 0.11313719],
           [ 0.47845647, 0.07533058, 0.11339844],
           [ 0.48366061, 0.07558282, 0.11362463],
           [ 0.48887111, 0.07581382, 0.11381491],
           [ 0.4940878 , 0.07602416, 0.1139684 ],
           [ 0.49931047, 0.07621457, 0.11408421],
           [ 0.50453883, 0.07638593, 0.11416144],
           [ 0.50977257, 0.07653932, 0.11419919],
           [ 0.5150113 , 0.07667605, 0.11419653],
           [ 0.52025455, 0.07679768, 0.11415256],
           [ 0.52550177, 0.07690603, 0.11406635],
           [ 0.53075236, 0.07700327, 0.11393703],
           [ 0.53600739, 0.07708717, 0.11376027],
           [ 0.5412669 , 0.07715821, 0.11353335],
           [ 0.54652771, 0.0772256 , 0.11325957],
           [ 0.55178873, 0.07729327, 0.11293812],
           [ 0.55705126, 0.0773588 , 0.11256303],
           [ 0.56231549, 0.07742288, 0.11212994],
           [ 0.56757608, 0.07750158, 0.11164576],
           [ 0.57283634, 0.07758744, 0.11109863],
           [ 0.57809224, 0.07769353, 0.1104918 ],
           [ 0.58334302, 0.07782425, 0.10982081],
           [ 0.58858654, 0.07798816, 0.10908346],
           [ 0.59382205, 0.07819019, 0.10827304],
           [ 0.59904386, 0.07844999, 0.10739406],
           [ 0.60425238, 0.07877012, 0.10643397],
           [ 0.60944301, 0.07916809, 0.10539092],
           [ 0.61461016, 0.07966497, 0.10426379],
           [ 0.61974864, 0.08028124, 0.10304728],
           [ 0.62485149, 0.08104315, 0.10173715],
           [ 0.62990947, 0.08198423, 0.10033109],
           [ 0.63491247, 0.08314096, 0.09882123],
           [ 0.6398442 , 0.08456761, 0.09721146],
           [ 0.64468435, 0.08632922, 0.0955073 ],
           [ 0.6494054 , 0.08850866, 0.09372537],
           [ 0.65397108, 0.0912077 , 0.09189703],
           [ 0.65833339, 0.09454784, 0.09009202],
           [ 0.66243651, 0.09864878, 0.08842866],
           [ 0.66622885, 0.10358333, 0.08708307],
           [ 0.66968657, 0.10931333, 0.08625839],
           [ 0.67283171, 0.11566769, 0.08610729],
           [ 0.6757203 , 0.12241372, 0.08666976],
           [ 0.67841932, 0.12933456, 0.08789535],
           [ 0.68098053, 0.13629052, 0.08968512],
           [ 0.68344163, 0.14319787, 0.09193958],
           [ 0.68583135, 0.15000536, 0.09457167],
           [ 0.68816291, 0.1567016 , 0.09751128],
           [ 0.69045161, 0.16327156, 0.10070151],
           [ 0.69270196, 0.16972257, 0.10409997],
           [ 0.69492052, 0.17605644, 0.10767181],
           [ 0.6971115 , 0.18227855, 0.11138953],
           [ 0.6992774 , 0.18839616, 0.11523156],
           [ 0.70141951, 0.19441742, 0.11918104],
           [ 0.70353886, 0.20034973, 0.12322434],
           [ 0.70564258, 0.20618991, 0.12734437],
           [ 0.70772377, 0.21195649, 0.13153872],
           [ 0.70978728, 0.21764841, 0.1357956 ],
           [ 0.71183309, 0.22327171, 0.14010893],
           [ 0.71386148, 0.22883139, 0.14447333],
           [ 0.71587167, 0.23433333, 0.1488853 ],
           [ 0.71786835, 0.23977551, 0.15333627],
           [ 0.71984546, 0.24517019, 0.1578295 ],
           [ 0.72180819, 0.25051406, 0.16235679],
           [ 0.72375695, 0.25581008, 0.16691534],
           [ 0.72568839, 0.26106558, 0.17150678],
           [ 0.72760326, 0.26628236, 0.17612862],
           [ 0.72950484, 0.27145906, 0.18077571],
           [ 0.73139331, 0.27659801, 0.1854465 ],
           [ 0.73326636, 0.28170419, 0.1901424 ],
           [ 0.73512444, 0.28677915, 0.19486192],
           [ 0.73696794, 0.29182437, 0.19960372],
           [ 0.73879722, 0.29684126, 0.20436661],
           [ 0.74061257, 0.3018312 , 0.20914956],
           [ 0.74241428, 0.3067955 , 0.21395164],
           [ 0.74420258, 0.31173541, 0.21877203],
           [ 0.74597769, 0.31665214, 0.22360999],
           [ 0.74773979, 0.32154685, 0.22846487],
           [ 0.74948906, 0.32642063, 0.23333611],
           [ 0.75122564, 0.33127454, 0.23822317],
           [ 0.75294966, 0.33610958, 0.2431256 ],
           [ 0.75466125, 0.34092672, 0.24804299],
           [ 0.75636051, 0.34572688, 0.25297497],
           [ 0.75804753, 0.35051093, 0.25792121],
           [ 0.75972242, 0.35527971, 0.26288139],
           [ 0.76138524, 0.36003402, 0.26785526],
           [ 0.76303608, 0.36477461, 0.27284255],
           [ 0.76467502, 0.36950222, 0.27784304],
           [ 0.76630212, 0.37421753, 0.28285652],
           [ 0.76791746, 0.37892121, 0.28788279],
           [ 0.76952314, 0.38361222, 0.29291941],
           [ 0.77111955, 0.38829095, 0.29796588],
           [ 0.77270462, 0.39295977, 0.30302441],
           [ 0.7742784 , 0.39761922, 0.30809485],
           [ 0.77584097, 0.40226986, 0.31317706],
           [ 0.77739238, 0.40691217, 0.31827091],
           [ 0.77893512, 0.41154481, 0.32337366],
           [ 0.78047016, 0.41616762, 0.32848423],
           [ 0.78199439, 0.42078349, 0.33360594],
           [ 0.78350789, 0.42539284, 0.33873868],
           [ 0.78501073, 0.42999609, 0.34388233],
           [ 0.78650668, 0.43459097, 0.34903287],
           [ 0.78799506, 0.43917847, 0.354191  ],
           [ 0.78947313, 0.44376102, 0.35935965],
           [ 0.79094096, 0.44833894, 0.36453871],
           [ 0.79240077, 0.45291112, 0.36972583],
           [ 0.79385565, 0.45747587, 0.37491782],
           [ 0.79530063, 0.46203701, 0.38011987],
           [ 0.79673584, 0.46659481, 0.38533185],
           [ 0.79816448, 0.47114749, 0.39055045],
           [ 0.79958815, 0.47569443, 0.39577406],
           [ 0.8010024 , 0.4802389 , 0.40100727],
           [ 0.80240737, 0.48478113, 0.40624996],
           [ 0.80380944, 0.48931741, 0.41149566],
           [ 0.80520425, 0.49385086, 0.41674883],
           [ 0.80659018, 0.49838283, 0.42201115],
           [ 0.80797029, 0.50291172, 0.42727955],
           [ 0.80934717, 0.50743629, 0.4325515 ],
           [ 0.81071558, 0.51196007, 0.43783228],
           [ 0.81207638, 0.5164828 , 0.44312105],
           [ 0.81343685, 0.52100046, 0.44841067],
           [ 0.8147893 , 0.52551795, 0.4537088 ],
           [ 0.81613394, 0.53003538, 0.45901524],
           [ 0.81747897, 0.5345483 , 0.46432204],
           [ 0.81881703, 0.53906126, 0.46963645],
           [ 0.8201478 , 0.54357471, 0.47495881],
           [ 0.82147918, 0.54808444, 0.48028157],
           [ 0.82280449, 0.55259451, 0.48561123],
           [ 0.82412305, 0.55710554, 0.49094847],
           [ 0.8254432 , 0.56161322, 0.49628544],
           [ 0.82675744, 0.56612192, 0.50162934],
           [ 0.82806604, 0.57063173, 0.50697994],
           [ 0.82937681, 0.57513873, 0.51233002],
           [ 0.83068173, 0.57964746, 0.51768714],
           [ 0.83198326, 0.58415686, 0.52304908],
           [ 0.83328588, 0.58866484, 0.5284118 ],
           [ 0.83458333, 0.5931749 , 0.53378113],
           [ 0.8358801 , 0.59768496, 0.53915303],
           [ 0.83717645, 0.60219516, 0.54452738],
           [ 0.83846835, 0.60670775, 0.54990789],
           [ 0.83976265, 0.61121955, 0.55528849],
           [ 0.8410547 , 0.61573311, 0.56067344],
           [ 0.84234408, 0.62024886, 0.56606321],
           [ 0.84363717, 0.62476392, 0.57145221],
           [ 0.84492701, 0.62928191, 0.57684673],
           [ 0.84621797, 0.63380094, 0.58224299],
           [ 0.84751018, 0.63832119, 0.58764099],
           [ 0.84879999, 0.64284461, 0.593044  ],
           [ 0.85009482, 0.64736793, 0.59844571],
           [ 0.85138839, 0.65189431, 0.60385164],
           [ 0.85268319, 0.65642282, 0.60925975],
           [ 0.85398149, 0.66095265, 0.61466822],
           [ 0.85527884, 0.66548603, 0.62008095],
           [ 0.85658162, 0.6700203 , 0.62549264],
           [ 0.85788519, 0.67455777, 0.63090732],
           [ 0.85919114, 0.67909794, 0.63632378],
           [ 0.86050197, 0.68363992, 0.64174006],
           [ 0.86181344, 0.68818579, 0.64715977],
           [ 0.86313161, 0.69273312, 0.65257806],
           [ 0.86445197, 0.69728408, 0.65799876],
           [ 0.86577662, 0.70183799, 0.66342026],
           [ 0.86710699, 0.70639443, 0.66884154],
           [ 0.86843979, 0.71095503, 0.67426538],
           [ 0.8697811 , 0.71551742, 0.67968704],
           [ 0.87112572, 0.72008401, 0.6851108 ],
           [ 0.87247699, 0.7246536 , 0.69053414],
           [ 0.87383465, 0.72922652, 0.69595742],
           [ 0.87519745, 0.7338035 , 0.70138174],
           [ 0.87656942, 0.73838308, 0.7068041 ],
           [ 0.87794657, 0.74296713, 0.71222776],
           [ 0.87933298, 0.74755418, 0.71764969],
           [ 0.88072655, 0.75214529, 0.72307166],
           [ 0.88212837, 0.75674024, 0.72849299],
           [ 0.88353983, 0.76133869, 0.73391278],
           [ 0.88495882, 0.76594169, 0.73933276],
           [ 0.88638969, 0.77054772, 0.74474984],
           [ 0.88782898, 0.77515837, 0.75016676],
           [ 0.88927961, 0.77977269, 0.7555815 ],
           [ 0.89074089, 0.78439118, 0.76099475],
           [ 0.89221327, 0.78901387, 0.76640633],
           [ 0.89369834, 0.79364037, 0.77181526],
           [ 0.89519472, 0.79827141, 0.77722272],
           [ 0.89670542, 0.80290607, 0.78262669],
           [ 0.8982287 , 0.80754523, 0.78802864],
           [ 0.89976654, 0.81218834, 0.79342729],
           [ 0.90131894, 0.81683563, 0.79882287],
           [ 0.90288651, 0.8214871 , 0.80421511],
           [ 0.9044705 , 0.82614249, 0.80960336],
           [ 0.90607068, 0.83080212, 0.81498794],
           [ 0.90768898, 0.83546549, 0.82036775],
           [ 0.90932516, 0.84013293, 0.82574316],
           [ 0.91098071, 0.8448041 , 0.83111336],
           [ 0.91265627, 0.84947901, 0.83647814],
           [ 0.91435297, 0.85415748, 0.84183697],
           [ 0.91607186, 0.85883936, 0.84718938],
           [ 0.91781428, 0.86352441, 0.85253473],
           [ 0.9195813 , 0.86821249, 0.85787257],
           [ 0.92137476, 0.87290318, 0.86320196],
           [ 0.92319608, 0.87759623, 0.86852224],
           [ 0.92504735, 0.88229114, 0.87383237],
           [ 0.92693098, 0.88698733, 0.87913111],
           [ 0.92884915, 0.8916843 , 0.8844174 ],
           [ 0.93080613, 0.89638082, 0.8896889 ],
           [ 0.93280442, 0.90107632, 0.89494445],
           [ 0.93485093, 0.90576867, 0.90018015],
           [ 0.93695162, 0.91045614, 0.9053928 ],
           [ 0.93911755, 0.91513525, 0.91057619],
           [ 0.94136572, 0.91980053, 0.91572063],
           [ 0.9437291 , 0.92444114, 0.92080706],
           [ 0.94634709, 0.92901013, 0.92575324]]

test_cm = ListedColormap(cm_data, name=__file__)


if __name__ == "__main__":
    import matplotlib.pyplot as plt
    import numpy as np

    try:
        from viscm import viscm
        viscm(test_cm)
    except ImportError:
        print("viscm not found, falling back on simple display")
        plt.imshow(np.linspace(0, 100, 256)[None, :], aspect='auto',
                   cmap=test_cm)
    plt.show()