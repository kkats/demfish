!
! 潮汐の時系列をあらかじめ計算して保存しておく。
!
! 定数は大文字
! 変数は小文字
      PROGRAM naomain
      IMPLICIT NONE
      INTEGER NX, NY, NT
      PARAMETER (NX=25, NY=61, NT=131473)! NT は naosub.f の idmax= の出力をみて決める。
                                         ! 2012/7/1 から 2014/12/31 を 5 分ごとに出力すると
                                         ! idmax=262945 で出力が 1.5 G bytes くらい。
                                         ! 10 分ごとで idmax=131473 で同 0.8 G bytes.
      DOUBLE PRECISION DT
      PARAMETER (DT=10.d0)
      REAL xs(NX), ys(NY), xstep, ystep
      REAL hout(NX,NY,NT)
      REAL tout(NT)
      DOUBLE PRECISION  TIMEORIGIN      ! 時間の基準。2012 年 4 月 1 日 00:00 UTC とする。
                                        ! nao99b/naotidej/README に UTC と明記されている。

      INTEGER iyear1, iyear2, imon1, imon2, iday1, iday2,
     &        ihour1, ihour2, imin1, imin2
      DOUBLE PRECISION  xmjd1, xmjd2
      INTEGER i,j


      call mjdymd (TIMEORIGIN, 2012, 4, 1, 0, 0, 0, 1)  ! 基準設定
      !
      ! 時刻出力
      !
      iyear1  = 2012 ! year
      imon1   =    7 ! month
      iday1   =    1 ! day
      ihour1  =    0 ! hour
      imin1   =    0 ! minute
      iyear2  = 2014 ! year
      imon2   =   12 ! month
      iday2   =   31 ! day
      ihour2  =    0 ! hour
      imin2   =    0 ! minute
      !
      ! 140E-144E
      !
      xstep = 1.0 / 6.0
      do i=1,NX
        xs(i) = 140 + (i-1) * xstep
      end do
      !
      ! 35N-45N
      !
      ystep = 1.0 / 6.0
      do j=1, NY
        ys(j) = 35 + (j-1) * ystep
      end do
      ! NAO99b による時系列が hout に計算される。
      ! 最後の引数は real では駄目で double precision
      call nao(xs, ys, NX, NY, NT, tout, hout, DT,
     &     iyear1, imon1, iday1, ihour1, imin1,
     &     iyear2, imon2, iday2, ihour2, imin2)
      !
      ! 生 binary ("access='direct'")で書き出すとGrADS で読める
      ! 巨大なファイルになるので出力先注意。
      !
      open(unit=19, file='/data/tmp/hout.bin', form='unformatted',
     &     access='direct', recl=NX*NY*NT*4)
      write(19,rec=1) hout
      close(19)
      call mjdymd(xmjd1, iyear1, imon1 , iday1 , ihour1,
     +            imin1, 0     , 1                      )
      call mjdymd(xmjd2, iyear2, imon2 , iday2 , ihour2,
     +            imin2, 0     , 1                      )
      ! 出力は fort.20 というファイルへ。
      write(20,101) xmjd1-TIMEORIGIN,
     +              imon1, iday1, iyear1, ihour1, imin1, 'start time'
      write(20,101) xmjd2-TIMEORIGIN,
     +              imon2, iday2, iyear2, ihour2, imin2, 'end time'
101        format(f18.6,i3,'/',i2,i5,i3,':',i2,a)


      END PROGRAM
