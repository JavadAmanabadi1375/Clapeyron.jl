# Example vector with NaN value
vec = [1, 2, NaN, 4, 5]

# Find the index of NaN value
nan_index = findfirst(isnan, vec)

if !isnothing(nan_index)
    # If NaN value is found, remove it from the vector
    println("Index of NaN value: ", nan_index)
    println("Removing NaN value from the vector...")
    deleteat!(vec, nan_index)
    println("Vector after removing NaN value: ", vec)
else
    println("No NaN value found in the vector.")
end