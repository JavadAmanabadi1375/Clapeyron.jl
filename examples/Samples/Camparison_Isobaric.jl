# This code is written for gathering data from SQLite 
using Pkg
using SQLite
using DataFrames
import PyPlot; const plt = PyPlot


const  R =8.314 #J/mole*k

Comparison_Compound=["Methane","Ethane","Propane","Butane","Pentane","Hexane","Heptane","Octane","Nonane","Decane"]
# Comparison_Compound=["Pentane"]
StatePlot="Isothermal" #You can choose either Isobaric or Isothermal
Comparison_Property="Cv_J_gk"

# Read data from database
db_path= raw"C:\Users\javam\Desktop\Study Plan\Db\PhdDb.db"
db=SQLite.DB(db_path)
plt.clf()
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

    if Comparison_Property =="Cp_J_gk" || Comparison_Property =="Cv_J_gk"
        

        plt.plot(xAxix,(df1.Cv_J_gk.*df_Mw.Mw)./R,label=element,linestyle=":")
        plt.ylabel("Cv/R",fontsize=16)


    else    

        plt.plot(xAxix,df1.JouleThomson_K_MPa,label=element,linestyle=":")
        plt.ylabel("$Comparison_Property",fontsize=16)


    end

    xlabelName= StatePlot=="Isobaric" ? "Tr" : "Pr" 
    plt.xlabel(xlabelName,fontsize=16)
    plt.legend(loc="lower right",frameon=false,fontsize=8)
    plt.title(condition1)
    display(plt.gcf())


end



