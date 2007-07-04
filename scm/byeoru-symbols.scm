;; -*- mode: scheme; coding: utf-8 -*-

;;; byeoru-symbols.scm: Symbols list for byeoru.scm
;;;
;;; Copyright (c) 2003-2007 uim Project http://code.google.com/p/uim/
;;;
;;; All rights reserved.
;;;
;;; Redistribution and use in source and binary forms, with or without
;;; modification, are permitted provided that the following conditions
;;; are met:
;;; 1. Redistributions of source code must retain the above copyright
;;;    notice, this list of conditions and the following disclaimer.
;;; 2. Redistributions in binary form must reproduce the above copyright
;;;    notice, this list of conditions and the following disclaimer in the
;;;    documentation and/or other materials provided with the distribution.
;;; 3. Neither the name of authors nor the names of its contributors
;;;    may be used to endorse or promote products derived from this software
;;;    without specific prior written permission.
;;;
;;; THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS ``AS IS'' AND
;;; ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
;;; IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
;;; ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT HOLDERS OR CONTRIBUTORS BE LIABLE
;;; FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
;;; DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
;;; OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
;;; HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
;;; LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
;;; OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
;;; SUCH DAMAGE.
;;;;

(define byeoru-menu-symbols
  '(("기호 문자"
     ;; symbols in EUC-KR
     12288
     12289
     12290
     183
     8229
     8230
     168
     12291
     173
     8213
     8741
     8764
     8216
     8217
     8220
     8221
     12308
     12309
     12296
     12297
     12298
     12299
     12300
     12301
     12302
     12303
     12304
     12305
     177
     215
     247
     8800
     8804
     8805
     8734
     8756
     176
     8242
     8243
     8451
     8491
     65510
     65504
     65505
     65509
     9794
     9792
     8736
     8869
     8978
     8706
     8711
     8801
     8786
     167
     8251
     9734
     9733
     9675
     9679
     9678
     9671
     9670
     9633
     9632
     9651
     9650
     9661
     9660
     8594
     8592
     8593
     8595
     8596
     12307
     8810
     8811
     8730
     8765
     8733
     8757
     8747
     8748
     8712
     8715
     8838
     8839
     8834
     8835
     8746
     8745
     8743
     8744
     65506
     8658
     8660
     8704
     8707
     180
     65374
     711
     728
     733
     730
     729
     184
     731
     161
     191
     720
     8750
     8721
     8719
     164
     8457
     8240
     9665
     9664
     9655
     9654
     9828
     9824
     9825
     9829
     9831
     9827
     8857
     9672
     9635
     9680
     9681
     9618
     9636
     9637
     9640
     9639
     9638
     9641
     9832
     9743
     9742
     9756
     9758
     182
     8224
     8225
     8597
     8599
     8601
     8598
     8600
     9837
     9833
     9834
     9836
     12927
     12828
     8470
     13255
     8482
     13250
     13272
     8481
     8364
     174
     ;; fullwidth symbols only in UCS-2
     65375
     65376
     65508
     ;; halfwidth symbols only in UCS-2
     65377
     65378
     65379
     65380
     65512
     65513
     65514
     65515
     65516
     65517
     65518)
    ("전각 기호"
     65281
     65282
     65283
     65284
     65285
     65286
     65287
     65288
     65289
     65290
     65291
     65292
     65293
     65294
     65295
     65306
     65307
     65308
     65309
     65310
     65311
     65312
     65339
     65340
     65341
     65342
     65343
     65344
     65371
     65372
     65373
     65507)
    ("단위 문자"
     13205
     13206
     13207
     8467
     13208
     13252
     13219
     13220
     13221
     13222
     13209
     13210
     13211
     13212
     13213
     13214
     13215
     13216
     13217
     13218
     13258
     13197
     13198
     13199
     13263
     13192
     13193
     13256
     13223
     13224
     13232
     13233
     13234
     13235
     13236
     13237
     13238
     13239
     13240
     13241
     13184
     13185
     13186
     13187
     13188
     13242
     13243
     13244
     13245
     13246
     13247
     13200
     13201
     13202
     13203
     13204
     8486
     13248
     13249
     13194
     13195
     13196
     13270
     13253
     13229
     13230
     13231
     13275
     13225
     13226
     13227
     13228
     13277
     13264
     13267
     13251
     13257
     13276
     13254)
    ("아라비아/로마 숫자"
     65296
     65297
     65298
     65299
     65300
     65301
     65302
     65303
     65304
     65305
     8560
     8561
     8562
     8563
     8564
     8565
     8566
     8567
     8568
     8569
     8544
     8545
     8546
     8547
     8548
     8549
     8550
     8551
     8552
     8553)
    ("한글 호환성 자모"
     12593
     12594
     12595
     12596
     12597
     12598
     12599
     12600
     12601
     12602
     12603
     12604
     12605
     12606
     12607
     12608
     12609
     12610
     12611
     12612
     12613
     12614
     12615
     12616
     12617
     12618
     12619
     12620
     12621
     12622
     12623
     12624
     12625
     12626
     12627
     12628
     12629
     12630
     12631
     12632
     12633
     12634
     12635
     12636
     12637
     12638
     12639
     12640
     12641
     12642
     12643
     12644
     12645
     12646
     12647
     12648
     12649
     12650
     12651
     12652
     12653
     12654
     12655
     12656
     12657
     12658
     12659
     12660
     12661
     12662
     12663
     12664
     12665
     12666
     12667
     12668
     12669
     12670
     12671
     12672
     12673
     12674
     12675
     12676
     12677
     12678
     12679
     12680
     12681
     12682
     12683
     12684
     12685
     12686)
    ("라틴 문자"
     65313
     65314
     65315
     65316
     65317
     65318
     65319
     65320
     65321
     65322
     65323
     65324
     65325
     65326
     65327
     65328
     65329
     65330
     65331
     65332
     65333
     65334
     65335
     65336
     65337
     65338
     65345
     65346
     65347
     65348
     65349
     65350
     65351
     65352
     65353
     65354
     65355
     65356
     65357
     65358
     65359
     65360
     65361
     65362
     65363
     65364
     65365
     65366
     65367
     65368
     65369
     65370
     198
     208
     170
     294
     306
     319
     321
     216
     338
     186
     222
     358
     330
     230
     273
     240
     295
     305
     307
     312
     320
     322
     248
     339
     223
     254
     359
     331
     329)
    ("그리스 문자"
     913
     914
     915
     916
     917
     918
     919
     920
     921
     922
     923
     924
     925
     926
     927
     928
     929
     931
     932
     933
     934
     935
     936
     937
     945
     946
     947
     948
     949
     950
     951
     952
     953
     954
     955
     956
     957
     958
     959
     960
     961
     963
     964
     965
     966
     967
     968
     969)
    ("박스 문자"
     ;; box drawing symbols in EUC-KR
     9472
     9474
     9484
     9488
     9496
     9492
     9500
     9516
     9508
     9524
     9532
     9473
     9475
     9487
     9491
     9499
     9495
     9507
     9523
     9515
     9531
     9547
     9504
     9519
     9512
     9527
     9535
     9501
     9520
     9509
     9528
     9538
     9490
     9489
     9498
     9497
     9494
     9493
     9486
     9485
     9502
     9503
     9505
     9506
     9510
     9511
     9513
     9514
     9517
     9518
     9521
     9522
     9525
     9526
     9529
     9530
     9533
     9534
     9536
     9537
     9539
     9540
     9541
     9542
     9543
     9544
     9545
     9546
     ;; box drawing symbols only in UCS-2
     9476
     9477
     9478
     9479
     9480
     9481
     9482
     9483
     9548
     9549
     9550
     9551
     9552
     9553
     9554
     9555
     9556
     9557
     9558
     9559
     9560
     9561
     9562
     9563
     9564
     9565
     9566
     9567
     9568
     9569
     9570
     9571
     9572
     9573
     9574
     9575
     9576
     9577
     9578
     9579
     9580
     9581
     9582
     9583
     9584
     9585
     9586
     9587
     9588
     9589
     9590
     9591
     9592
     9593
     9594
     9595
     9596
     9597
     9598
     9599)
    ("원문자"
     12896
     12897
     12898
     12899
     12900
     12901
     12902
     12903
     12904
     12905
     12906
     12907
     12908
     12909
     12910
     12911
     12912
     12913
     12914
     12915
     12916
     12917
     12918
     12919
     12920
     12921
     12922
     12923
     9424
     9425
     9426
     9427
     9428
     9429
     9430
     9431
     9432
     9433
     9434
     9435
     9436
     9437
     9438
     9439
     9440
     9441
     9442
     9443
     9444
     9445
     9446
     9447
     9448
     9449
     9312
     9313
     9314
     9315
     9316
     9317
     9318
     9319
     9320
     9321
     9322
     9323
     9324
     9325
     9326)
    ("괄호 문자"
     12800
     12801
     12802
     12803
     12804
     12805
     12806
     12807
     12808
     12809
     12810
     12811
     12812
     12813
     12814
     12815
     12816
     12817
     12818
     12819
     12820
     12821
     12822
     12823
     12824
     12825
     12826
     12827
     9372
     9373
     9374
     9375
     9376
     9377
     9378
     9379
     9380
     9381
     9382
     9383
     9384
     9385
     9386
     9387
     9388
     9389
     9390
     9391
     9392
     9393
     9394
     9395
     9396
     9397
     9332
     9333
     9334
     9335
     9336
     9337
     9338
     9339
     9340
     9341
     9342
     9343
     9344
     9345
     9346)
    ("분수/첨자"
     189
     8531
     8532
     188
     190
     8539
     8540
     8541
     8542
     185
     178
     179
     8308
     8319
     8321
     8322
     8323
     8324)
    ("히라가나"
     12353
     12354
     12355
     12356
     12357
     12358
     12359
     12360
     12361
     12362
     12363
     12364
     12365
     12366
     12367
     12368
     12369
     12370
     12371
     12372
     12373
     12374
     12375
     12376
     12377
     12378
     12379
     12380
     12381
     12382
     12383
     12384
     12385
     12386
     12387
     12388
     12389
     12390
     12391
     12392
     12393
     12394
     12395
     12396
     12397
     12398
     12399
     12400
     12401
     12402
     12403
     12404
     12405
     12406
     12407
     12408
     12409
     12410
     12411
     12412
     12413
     12414
     12415
     12416
     12417
     12418
     12419
     12420
     12421
     12422
     12423
     12424
     12425
     12426
     12427
     12428
     12429
     12430
     12431
     12432
     12433
     12434
     12435)
    ("카타카나"
     12449
     12450
     12451
     12452
     12453
     12454
     12455
     12456
     12457
     12458
     12459
     12460
     12461
     12462
     12463
     12464
     12465
     12466
     12467
     12468
     12469
     12470
     12471
     12472
     12473
     12474
     12475
     12476
     12477
     12478
     12479
     12480
     12481
     12482
     12483
     12484
     12485
     12486
     12487
     12488
     12489
     12490
     12491
     12492
     12493
     12494
     12495
     12496
     12497
     12498
     12499
     12500
     12501
     12502
     12503
     12504
     12505
     12506
     12507
     12508
     12509
     12510
     12511
     12512
     12513
     12514
     12515
     12516
     12517
     12518
     12519
     12520
     12521
     12522
     12523
     12524
     12525
     12526
     12527
     12528
     12529
     12530
     12531
     12532
     12533
     12534)
    ("러시아 문자"
     1040
     1041
     1042
     1043
     1044
     1045
     1025
     1046
     1047
     1048
     1049
     1050
     1051
     1052
     1053
     1054
     1055
     1056
     1057
     1058
     1059
     1060
     1061
     1062
     1063
     1064
     1065
     1066
     1067
     1068
     1069
     1070
     1071
     1072
     1073
     1074
     1075
     1076
     1077
     1105
     1078
     1079
     1080
     1081
     1082
     1083
     1084
     1085
     1086
     1087
     1088
     1089
     1090
     1091
     1092
     1093
     1094
     1095
     1096
     1097
     1098
     1099
     1100
     1101
     1102
     1103)))
