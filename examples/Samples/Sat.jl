
using Clapeyron, PyCall
using SQLite
using DataFrames
using Statistics
using ExcelFiles
using XLSX
import PyPlot; const plt = PyPlot


const  R =8.314 #J/mole*k

StatePlot="L" #You can choose either Isobaric or Isothermal
Comparison_Property=["Density_Kg_m3","Psat"]
# Comparison_Property=["Psat"]

# Comparison_Compound=["ethane","propane","butane","pentane","hexane","heptane","octane","nonane","decane"]
# Comparison_Compound=["nonane","decane"]
Comparison_Compound=["methane"]


# Read data from database
db_path= raw"C:\Users\javam\OneDrive - Danmarks Tekniske Universitet\PhD\Database\RegionsT.db"
db=SQLite.DB(db_path)


# Open the Excel file
file_path="C:\\Users\\javam\\OneDrive - Danmarks Tekniske Universitet\\PhD\\Packages\\Clapeyron\\Clapeyron.jl\\examples\\Samples\\AARDF.xlsx"


global  cellNo=6

foreach(Comparison_Compound) do CompoundName
    CompoundNameK=uppercasefirst(CompoundName)
    # CompoundNameK="CarbonDioxide"

    model1 = SRK([CompoundName];idealmodel=WalkerIdeal)
    model2 = PR([CompoundName];idealmodel=WalkerIdeal)
    model3 = CPA([CompoundName];idealmodel=WalkerIdeal,radial_dist = :KG,cubicmodel=RK,alpha=SoaveAlpha)
    model4 = CKSAFT([CompoundName];idealmodel=WalkerIdeal)
    model5 = PCSAFT([CompoundName];idealmodel=WalkerIdeal)
    model6 = SAFTVRMie([CompoundName];idealmodel=WalkerIdeal)
    model7 = SAFTgammaMie([CompoundName];idealmodel=WalkerIdeal)
    model8 = GERG2008([CompoundName])

    models = [model1,model2,model3,model4,model5,model6,model7,model8];
    model_lenght=length(models)

    TableName=CompoundNameK*"_"*"SatL"
    qs_sat="SELECT * FROM $TableName"
    data_sat = SQLite.DBInterface.execute(db, qs_sat)
    df_sat = DataFrames.DataFrame(data_sat)

    qs_Mw="SELECT * FROM Com_Properties WHERE ComName== '$CompoundNameK'" 
    data_Mw = SQLite.DBInterface.execute(db, qs_Mw)
    df_Mw = DataFrames.DataFrame(data_Mw)
    Tc=df_Mw.Tc_k
    Dc=df_Mw.Dc_mol_L

    T = df_sat.Temperature_k 
 
    foreach(Comparison_Property) do property
                    
            Cp = []
            sat = []
            p = []
            v_l = []
            v_v = []

        for i ∈ 1:1

                sat = saturation_pressure.(models[i],T)
                append!(p,[[sat[j][1] for j ∈ 1:length(T)]])
                append!(v_l,[[sat[j][2] for j ∈ 1:length(T)]])
                append!(v_v,[[sat[j][3] for j ∈ 1:length(T)]])
        
            
          
            if property=="Density_Kg_m3"
    
    
                # exp_values=df1.Density_Kg_m3.*1000/(df_Mw.Mw)
                exp_values=df_sat.Density_mol_L*1e3
                Cp= 1e0./v_l[1]

                    # CPA Model results ------------------------------------
                    # TableNameC=CompoundNameK*"_"*"CPA"
                    # conditionTr="Round(Temperature_k / $df_Mw_Tc_k,2)==0.9" 
                    # qs_CERE = "SELECT * FROM $TableNameC WHERE $conditionTr"
                    # data_CERE = SQLite.DBInterface.execute(db, qs_CERE)
                    # df_CERE = DataFrames.DataFrame(data_CERE)
                    # Cp=df_CERE.Ro
                    #-------------------CPA Model results---------------------

                if i==1
                    sheetname="J"
 
                elseif i==2 
                    sheetname="N"

                elseif i==3
                    sheetname="R"

                elseif i==4
                    sheetname="V"

                elseif i==5
                    sheetname="Z"

                elseif i==6
                    sheetname="AH"

                elseif i==7
                    sheetname="AL"

                elseif i==8
                    sheetname="AP"

                end
    
            elseif property=="Psat"

                # TableNameC=CompoundNameK*"_"*"CPA"
                # conditionTr="Round(Temperature_k / $df_Mw_Tc_k,2)==0.9" 
                # qs_CERE = "SELECT * FROM $TableNameC WHERE $conditionTr"
                # data_CERE = SQLite.DBInterface.execute(db, qs_CERE)
                # df_CERE = DataFrames.DataFrame(data_CERE)
                # Cp=df_CERE.Psat


                exp_values=df_sat.Pressure_MPa*1e6    #change to MPa
                Cp=p[1]


                if i==1
                    sheetname="K"
 
                elseif i==2 
                    sheetname="O"

                elseif i==3
                    sheetname="S"

                elseif i==4
                    sheetname="W"

                elseif i==5
                    sheetname="AA"

                elseif i==6
                    sheetname="AI"

                elseif i==7
                    sheetname="AM"

                elseif i==8
                    sheetname="AQ"

                end
    
            end
        

                # # Find the index of NaN value
                non_nan_indices = [j for (j, x) in enumerate(Cp) if (isnan(x) || isinf(x))]
                foreach(reverse(non_nan_indices)) do y
                    deleteat!(Cp, y)
                    deleteat!(exp_values, y)
    
                end
                
                # ABSOLUTE RELATIVE DEVIATION       
                ARD = abs.((Cp) - (exp_values))
    
                # AVERAGE ABSOLUTE RELATIVE DEVIATION
                AARD = 100 * abs.(mean((ARD ./ abs.(exp_values))))
    
                    XLSX.openxlsx(file_path, mode="rw") do xf
    
                        sheet=xf[1]
    
                        sheet[sheetname*"$cellNo"]=AARD
                    
                    end
        end

    end
    
   global  cellNo += 1
end


