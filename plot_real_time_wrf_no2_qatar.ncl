; Clint Aegerter
; Plots NO2 ppmv for the real-time WRF run

;  LOAD FUNCTIONS AND PROCEDURES
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/wrf/WRFUserARW.ncl"

begin

; Basic resources
res = True
res@MainTitle = "UNL Real-Time WRF"
res@Footer = False
mpres = True
pltres = True

; Plot type
;type  = "X11"
type = "png"
;type = "ps"
;type = "pdf

; WRF output directory (COMMENT OUT FOR REAL-TIME RUN)
;dir       = "/work/jwang7/caegerter/WRF/output/qatar/"
;filelist  = "2015051512_list"

str       = "string"
filename  = asciiread(dir + filelist, -1, str)
nfile     = dimsizes(filename)

; Map settings
;minlat = 38.0
;maxlat = 44.0
;minlon = -105.0
;maxlon = -95.0

; Map resources
mpres@mpGridAndLimbOn              = False
mpres@mpProjection                 = "CylindricalEquidistant"
mpres@mpGeophysicalLineColor       = "Black"
mpres@mpNationalLineColor          = "Black"
mpres@mpUSStateLineColor           = "Black"
mpres@mpGeophysicalLineThicknessF  = 3.0
mpres@mpNationalLineThicknessF     = 3.0
mpres@mpUSStateLineThicknessF      = 3.0
mpres@mpOutlineBoundarySets        = "AllBoundaries"
mpres@mpDataBaseVersion            = "Ncarg4_1"
mpres@mpDataSetName                = "Earth..2"
mpres@gsnMaximize                  = True
mpres@mpFillDrawOrder              = "PreDraw"
mpres@tmXBLabelsOn                 = False
mpres@tmYLLabelsOn                 = False
mpres@tmXBMajorLengthF             = 0.0
mpres@tmYLMajorLengthF             = 0.0

plot   = new(1, graphic)

; Do loop to read and plot each file
do i = 0, nfile-1
 a = addfile(dir + filename(i) + ".nc", "w")
 time = charactertostring(a->Times(0, :))
 origInitTime = a@START_DATE
 a@START_DATE = str_sub_str(a@START_DATE, "_", " ")
 a@START_DATE = a@START_DATE + " UTC"
 timeLabel = str_sub_str(time, "_", " ")
 res@TimeLabel = timeLabel + " UTC"
 fileTime = str_sub_str(time, ":", "_")
 lat  = a->XLAT
 lon  = a->XLONG

 wks   = gsn_open_wks(type, dir + "images/no2/" + "WRF_no2_" + fileTime)

 gsn_define_colormap(wks,"BlAqGrYeOrReVi200")
  
 ; NO2
 no2_orig   = wrf_user_getvar(a, "no2", 0)
 no2   = no2_orig(0,:,:)
  no2@description = "NO~B~2~N~ Mixing Ratio"
  no2@units = "ppmv"
 printMinMax (no2, True)

 ; Wind
 u   = wrf_user_getvar(a, "ua", 0)
 v   = wrf_user_getvar(a, "va", 0)
 u10 = wrf_user_getvar(a, "U10", 0)
 v10 = wrf_user_getvar(a, "V10", 0)
 u10 = u10*1.94386 ; convert to knots
 v10 = v10*1.94386
  u10@units = "kts"
  v10@units = "kts"
  u10@lat2d = a->XLAT(0,:,:)
  v10@lon2d = a->XLONG(0,:,:)

 ; Pressure
 p   = wrf_user_getvar(a, "pressure", 0)
 slp = wrf_user_getvar(a, "slp", 0) ; sea-level pressure
 wrf_smooth_2d(slp, 3)
  slp@lat2d = a->XLAT(0,:,:)
  slp@lon2d = a->XLONG(0,:,:)
 
 ; SURFACE VARIABLE PLOTTING OPTIONS ==========================================
 ; Plotting options for NO2
 opts                      = res
 opts@cnFillOn             = True
 opts@ContourParameters    = (/.005, .05, .005/)
 opts@cnExplicitLabelBarLabelsOn = True
; opts@lbLabelStrings = (/"","0.01","","0.02","","0.03","","0.04","","0.05","","0.06","","0.07","","0.08","","0.09","","1.0"/)
 opts@pmLabelBarWidthF     = 0.875
 opts@pmLabelBarHeightF    = 0.2
 opts@pmLabelBarOrthogonalPosF = -.075
 opts@gsnSpreadColors      = True
; opts@gsnSpreadColorStart  = 0
; opts@cnLineLabelsOn      = True
; opts@cnLineLabelBackgroundColor = "Grey"
 contour_no2                = wrf_contour(a, wks, no2, opts)
 delete(opts)

 ; Plotting options for wind
 opts            = res
 opts@FieldTitle = "Wind"
 opts@NumVectors = 30
 vector          = wrf_vector(a, wks, u10, v10, opts)
 delete(opts)

 ; Plotting options for sea-level pressure
 opts                                = res
 opts@cnLineColor                    = "Black"
 opts@cnHighLabelsOn                 = True
 opts@cnLowLabelsOn                  = True
 opts@ContourParameters              = (/900., 1100., 4./)
 opts@cnLineLabelBackgroundColor     = "White"
 opts@cnLabelDrawOrder               = "PostDraw"
 opts@cnLineThicknessF               = 2.0
 opts@cnInfoLabelOn                  = False
 contour_slp                         = wrf_contour(a, wks, slp, opts)
 delete(opts)

 ; Make plot
 plot = wrf_map_overlays(a, wks, (/contour_no2, vector, contour_slp/), pltres, mpres)

a@START_DATE = origInitTime
end do

end
