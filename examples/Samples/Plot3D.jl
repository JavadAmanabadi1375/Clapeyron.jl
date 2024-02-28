# This code is written for gathering data from SQLite 
using Pkg
using SQLite
using DataFrames
import PyPlot; const plt = PyPlot
using Plots

const  R =8.314 #J/mole*k

Comparison_Compound=["Methane","Ethane","Propane","Butane","Pentane","Hexane","Heptane","Octane","Nonane","Decane"]
# Comparison_Compound=["Pentane"]
StatePlot="Isothermal" #You can choose either Isobaric or Isothermal
Comparison_Property="Cp_J_gk"

# Read data from database
db_path= raw"C:\Users\javam\Desktop\Study Plan\Db\PhdDb.db"
db=SQLite.DB(db_path)
plt.clf()
i=1
foreach(Comparison_Compound) do element

    TableName=element*"_"*StatePlot

    condition1= StatePlot=="Isothermal" ? "Temperature_k==500" : "Pressure_MPa==20"

    
    qs1 = "SELECT * FROM $TableName WhERE $condition1"
    data1 = SQLite.DBInterface.execute(db, qs1)
    df1 = DataFrames.DataFrame(data1)

    qs_Mw="SELECT * FROM Com_Properties WHERE ComName== '$element'" 
    data_Mw = SQLite.DBInterface.execute(db, qs_Mw)
    df_Mw = DataFrames.DataFrame(data_Mw)


    x1= StatePlot=="Isobaric" ? df1.Temperature_k : df1.Pressure_MPa
    xAxix= StatePlot=="Isobaric" ? x1./df_Mw.Tc_k : x1./df_Mw.Pc_MPa
    # xAxix= StatePlot=="Isobaric" ? x1 : x1


    elemen=lowercasefirst(element)
    
        # model1 = SRK([CompoundName])
        # model1 = SRK([CompoundName];idealmodel=JobackIdeal)
        # model2 = JobackIdeal([CompoundName])
        model3 = GERG2008([elemen])
        # model4 = CKSAFT([CompoundName];idealmodel=JobackIdeal)
        # model5 = SAFTgammaMie([CompoundName];idealmodel=JobackIdeal)
        # model6 = PR([CompoundName];idealmodel=JobackIdeal)
        # model7 = PCSAFT([CompoundName];idealmodel=JobackIdeal)
        # # model9 = PR([CompoundName];)
        # model8 = vdW([CompoundName];idealmodel=JobackIdeal)
        # model9 = CPA([CompoundName];idealmodel=JobackIdeal)
        models = [model3];
    
    
    
    
    p = df1.Pressure_MPa.*1e6
    T =  500
    Cp = []
    model_lenght=length(models)
    for i ∈ 1:model_lenght
        # append!(Cp,[speed_of_sound.(models[i],p,T)])
        append!(Cp,[isochoric_heat_capacity.(models[i],p,T)])
        # append!(Cp,[isobaric_heat_capacity.(models[i],p,T)])
        # append!(Cp,[joule_thomson_coefficient.(models[i],p,T)])
    end
    aa=element*"$i"
    tt=ones(length(xAxix).*T)
   aa =plot3d(
    xAxix, tt, Cp[1], # Plot methane data
    seriestype = :scatter,
    xlabel = "Pr",
    ylabel = "T",
    zlabel = "Cp",
    label = "Methane"
    
    )
    display(aa)


end



