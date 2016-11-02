# demfish

Process biologging data from tagged demersal fish

This set of Matlab scripts is prepared for analysing output from a logger
attached to demersal fish. A logger outputs time series of temperature
and pressure. Amplitude and phase of diurnal and semidiurnal astronomical
tides are used to estimate the location of the fish.

## Requirements
We do not provide the following data with this software. You need to modify
the code to read these data. Look for comments `%%%IO` in `tseries_to_points.m`.
Example scripts are found in the `example/` directory.

### Logger output
Time series of temperature and pressure.

### Tide model output
Time series of surface height `hout(i,j,k)` is necessary.
`hout(i,j,k)` is the predicted surface height in meters, at longitudinal
grid `i` and latitudinal grid `j`. The following variables are defined
and used to specify the grid in `tseries_to_points.m`.

* `LONGITUDE` is a vector with a length of `NX`.
* `LATITUDE` is a vector with a length of `NY`
* `DT` is the time step in minute. Length of the time series is `NT`.

We used [NAO.99b tidal prediction system](http://www.miz.nao.ac.jp/staffs/nao99/index_En.html).

### Bathymetry data
The ocean depth data are necessary. The grid can be different from
the grid used in the tide model output. If so, linear interpolation
is used. The following variables should be defined in `tseries_to_points.m`.

* `TOPOLON` is a vector for longitude.
* `TOPOLAT` is a vector for latitude.
* `TOPOZ` is a matrix where `TOPO(i,j)` is the depth in meters at `TOPOLON(i), TOPOLAT(j)`.

### Numerical simulation
A novelty in the present approach is the use of temperature. Data of temperature near/on seabed
is not usually available and we need to turn to simulation. We used output from
[JCOPE](http://www.jamstec.go.jp/jcope/htdocs/e/home.html) model. The output should be
readable from `points_with_temps.m`.

## How to run

Given all required data described above and relevant reading functions are implemented;

1. `tseries_to_points.m` to estimate candidate points.
2. `points_with_temps.m` to add temperature from simulation to the candidate points.
3. `temps_to_track.m` to examine candidate points and find most likely fish track.

## Reference

[Kawabe, R.](https://sites.google.com/site/biologgingkawabehp/home), Katsumata, K., in preparation

## History

0.1 -- Repository created on GitHub

## TODO

* Need to despike time series before analysis?
* Better gridding of topography near the coast -- probably all NaN's (v0.1).
