
using Clapeyron, PyCall
using SQLite
using DataFrames
using Statistics
using ExcelFiles
using XLSX
import PyPlot; const plt = PyPlot


const  R =8.314 #J/mole*k

StatePlot="L" #You can choose either Isobaric or Isothermal
CompoundName="heptane"

# Read data from database
db_path= raw"C:\Users\javam\OneDrive - Danmarks Tekniske Universitet\PhD\Database\RegionsT.db"
db=SQLite.DB(db_path)

# Open the Excel file
file_path="C:\\Users\\javam\\OneDrive - Danmarks Tekniske Universitet\\PhD\\Packages\\Clapeyron\\Clapeyron.jl\\examples\\Samples\\AARDF.xlsx"


db_pathT= raw"C:\Users\javam\OneDrive - Danmarks Tekniske Universitet\PhD\Database\PhDdb.db"
dbT=SQLite.DB(db_pathT)

Tr=[0.7]

plt.clf()
fig_alph, ax_alph = plt.subplots(2,2,figsize=[12, 9])

foreach(Tr) do Temperature

    CompoundNameK=uppercasefirst(CompoundName)

    # model1 = SRK([CompoundName];idealmodel=JobackIdeal)
    # model2 = CPA([CompoundName];idealmodel=JobackIdeal,radial_dist = :KG,cubicmodel=RK,alpha=SoaveAlpha)
    model3 = PCSAFT([CompoundName];idealmodel=JobackIdeal)
    model4 = SAFTVRMie([CompoundName];idealmodel=JobackIdeal)
    model5 = SAFTgammaMie([CompoundName];idealmodel=JobackIdeal)

    models = [model3,model4,model5];
    model_lenght=length(models)

    qs_Mw="SELECT * FROM Com_Properties WHERE ComName== '$CompoundNameK'" 
    data_Mw = SQLite.DBInterface.execute(db, qs_Mw)
    df_Mw = DataFrames.DataFrame(data_Mw)
    df_Mw_Tc_k=df_Mw.Tc_k[1]

    TableName=CompoundNameK*"_"*StatePlot
    condition1= StatePlot=="L" ? "Round(Temperature_k / $df_Mw_Tc_k,2)==$Temperature" : "Pressure_MPa==20"
    qs1 = "SELECT * FROM $TableName WhERE $condition1"
    data1 = SQLite.DBInterface.execute(db, qs1)
    df1 = DataFrames.DataFrame(data1)
    x1= StatePlot=="Isobaric" ? df1.Temperature_k : df1.Pressure_MPa
    p = df1.Pressure_MPa.*1e6
    T=df1.Temperature_k[1]

    conditionT= "Pressure_MPa==20"
    qsT = "SELECT * FROM Heptane_Isobaric WhERE $conditionT"
    # qs1 = "SELECT * FROM $TableName WhERE $condition1 AND Phase=='liquid'"
    # qs1 = "SELECT * FROM $TableName WhERE $condition1 AND Phase=='liquid' AND Pressure_MPa>7" 
    dataT = SQLite.DBInterface.execute(dbT, qsT)
    dfT = DataFrames.DataFrame(dataT)

    p = 20*1e6
    T=dfT.Temperature_k
    xAxis=T

    ∂Ares∂V=[]
    ∂Areshs∂V=[]
    ∂Areschain∂V=[]
    ∂Aresdisp∂V=[]


    for i=1:model_lenght

       dAres= Gathering_Res_Derivatives.(models[i],p,T)
       dAhs= Gathering_Derivatives_hs.(models[i],p,T)
       dAchain= Gathering_Derivatives_chain.(models[i],p,T)
       dAdisp= Gathering_Derivatives_disp.(models[i],p,T)
       append!(∂Ares∂V,[[dAres[i][6] for i ∈ 1:length(T)]])
       append!(∂Areshs∂V,[[dAhs[i][6] for i ∈ 1:length(T)]])
       append!(∂Areschain∂V,[[dAchain[i][6] for i ∈ 1:length(T)]])
       append!(∂Aresdisp∂V,[[dAdisp[i][6] for i ∈ 1:length(T)]])

    end

    ax_alph[1,1].plot(xAxis./df_Mw_Tc_k,∂Areshs∂V[1]*1e-6,label="PCSAFT",linestyle="--",color="g",linewidth=2)
    ax_alph[1,1].plot(xAxis./df_Mw_Tc_k,∂Areshs∂V[2]*1e-6,label="SAFT-VR Mie",linestyle="-.",color="b",linewidth=2)
    ax_alph[1,1].plot(xAxis./df_Mw_Tc_k,∂Areshs∂V[3]*1e-6,label="SAFT-γ Mie",color="k",linewidth=2)
    ax_alph[1,1][:set_xlabel]("Tr",fontsize=14)
    ax_alph[1,1][:set_ylabel]("\$∂A_{hs}^{res}/∂V\\:(J\\:\\cdot K^{-1}\\cdot m^{3})\\cdot 1e6\$",fontsize=14)
    ax_alph[1,1].legend(loc="lower right",frameon=false,fontsize=10)

    ax_alph[1,2].plot(xAxis./df_Mw_Tc_k,-∂Areschain∂V[1]*1e-6,label="PCSAFT",linestyle="--",color="g",linewidth=2)
    ax_alph[1,2].plot(xAxis./df_Mw_Tc_k,∂Areschain∂V[2]*1e-6,label="SAFT-VR Mie",linestyle="-.",color="b",linewidth=2)
    ax_alph[1,2].plot(xAxis./df_Mw_Tc_k,∂Areschain∂V[3]*1e-6,label="SAFT-γ Mie",color="k",linewidth=2)
    ax_alph[1,2][:set_xlabel]("Tr",fontsize=14)
    ax_alph[1,2][:set_ylabel]("\$∂A_{chain}^{res}/∂V\\:(J\\:\\cdot K^{-1}\\cdot m^{3})\\cdot 1e6\$",fontsize=14)
    ax_alph[1,2].legend(loc="upper right",frameon=false,fontsize=10)

    ax_alph[2,1].plot(xAxis./df_Mw_Tc_k,∂Aresdisp∂V[1]*1e-6,label="PCSAFT",linestyle="--",color="g",linewidth=2)
    ax_alph[2,1].plot(xAxis./df_Mw_Tc_k,∂Aresdisp∂V[2]*1e-6,label="SAFT-VR Mie",linestyle="-.",color="b",linewidth=2)
    ax_alph[2,1].plot(xAxis./df_Mw_Tc_k,∂Aresdisp∂V[3]*1e-6,label="SAFT-γ Mie",color="k",linewidth=2)
    ax_alph[2,1][:set_xlabel]("Tr",fontsize=14)
    ax_alph[2,1][:set_ylabel]("\$∂A_{disp}^{res}/∂V\\:(J\\:\\cdot K^{-1}\\cdot m^{3})\\cdot 1e6\$",fontsize=14)
    ax_alph[2,1].legend(loc="upper right",frameon=false,fontsize=10)

    ax_alph[2,2].plot(xAxis./df_Mw_Tc_k,∂Ares∂V[1]*1e-6,label="PCSAFT",linestyle="--",color="g",linewidth=2)
    ax_alph[2,2].plot(xAxis./df_Mw_Tc_k,∂Ares∂V[2]*1e-6,label="SAFT-VR Mie",linestyle="-.",color="b",linewidth=2)
    ax_alph[2,2].plot(xAxis./df_Mw_Tc_k,∂Ares∂V[3]*1e-6,label="SAFT-γ Mie",color="k",linewidth=2)
    ax_alph[2,2][:set_xlabel]("Tr",fontsize=14)
    ax_alph[2,2][:set_ylabel]("\$∂A^{res}/∂V\\:(J\\:\\cdot K^{-1}\\cdot m^{3})\\cdot 1e6\$",fontsize=14)
    ax_alph[2,2].legend(loc="upper left",frameon=false,fontsize=10)

end
display(plt.gcf())
plt.savefig("∂A∂V.pdf")



