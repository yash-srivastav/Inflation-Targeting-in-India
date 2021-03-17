import excel "/Users/yashsrivastav/Desktop/Thesis Data/2.17.21.xlsx", firstrow
egen ID = group(Country_Name)
gen int_term = (Country_Name == "India") & (Year >= 2015)
*save "/Users/yashsrivastav/Desktop/Thesis Data/panel_data.xlsx", replace


*fixed effects diff-in-diff
reg inf_rate lag_unemp int_term i.ID i.Year, robust cl(ID) 
reg inf_rate lag_unemp lag_inf_rate int_term i.ID i.Year, robust cl(ID) 
*estimates store model1


*to test for bias prior to policy intervention, placebo dummy tells us 
*if we're violating parallel trends assumption; if negative coefficient on placebo this indicates inflation was already trending lower for India 
gen placebo=(Country_Name=="India" & Year==2014)
reg inf_rate lag_unemp int_term placebo i.ID i.Year, robust cl(ID) 
eststo: reg inf_rate lag_unemp int_term placebo i.ID i.Year, robust cl(ID)
esttab using regtable1.tex, label nostar
reg inf_rate lag_unemp int_term placebo i.ID i.Year, robust cl(ID)
*this regression sees if linear time trends can eliminate parallel trends violation  
reg inf_rate lag_unemp int_term placebo i.ID i.Year ZCC*, robust cl(ID)
*estimates store model3
*esttab model1 model2 model3 using table5.tex, stats(r2 df_r bic)

*synthetic control
ssc install synth, replace all
tsset ID Year
synth inf_rate lag_unemp inf_rate(2014) inf_rate(2010) inf_rate(2007), nested trunit(10) trperiod(2015) fig 

synth inf_rate lag_unemp lag_inf_rate inf_rate(2014) inf_rate(2010) inf_rate(2007), nested trunit(10) trperiod(2015) fig 

*visual display of inflation in India
line inf_rate Year if Country_Name=="India", title("Inflation in India") ytitle("inflation rate")

*VARs 
varbasic inf_rate lag_inf_rate lag_unemp if Country_Name=="India"

*computing inflation volatility as 6 month rolling standard deviation of India CPI; data preparation
import excel "/Users/yashsrivastav/Downloads/INDCPIALLMINMEI.xls", sheet("FRED Graph") firstrow clear
gen daten = mofd(observation_date)
tsset daten
gen year=year(dofd(observation_date))

*annualized CPI growth
gen ann_cpi = (((cpi/cpi[_n-1])^12)-1)*100

*creating volatility measure
for num 1/4: gen tmpX = cpi[_n-X]
egen sd = rsd(tmp*) if tmp4!=.
for num 1/4: drop tmpX

line sd observation_date if year>2005

gen post15 = 0 
replace post15 = 1 if year>=2015

for num 1/4: gen tempX = ann_cpi[_n-X]
egen sd1 = rsd(temp*) if temp4!=.
for num 1/4: drop tempX
line sd1 observation_date if year>=2005
gen L1sd1 = sd[_n-1]
reg sd1 post15, robust


*log difference
gen logcpi = log(cpi)
gen fdlogcpi = logcpi = L.logcpi
arch fdlogcpi, arch(1)


*AR(1) 
gen L1sd = sd[_n-1]
reg sd L1sd post15 if year>=2000, robust
dfuller sd

*ARCH model
arch sd, arch(1/3)


*analysis phase
import dta "/Users/yashsrivastav/Desktop/Thesis Data/cpi.dta"



save "/Users/yashsrivastav/Desktop/Thesis Data/cpi1.dta"


