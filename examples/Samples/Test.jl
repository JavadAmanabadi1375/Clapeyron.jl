# Example vector with NaN value
Cp=[]
# append!(Cp,[1.54585,2,3,4.585858,5,NaN, NaN,NaN,Inf,Inf])
Cp=[1.54585,2,3,4.585858,5,NaN, NaN,NaN,Inf,Inf]
exp_values=[1,2,3,4,5,6,7,8,9.8585,10]

        # Find the index of NaN value
        non_nan_indices = [j for (j, x) in enumerate(Cp) if (isnan(x) || isinf(x))]
        foreach(reverse(non_nan_indices)) do y
            deleteat!(Cp, y)
            deleteat!(exp_values, y)

        end

aa=[(1,2,3),(4,5,6),(7,8,9)]
first_elements = [x[1] for x in aa]
println(first_elements)
a=3

