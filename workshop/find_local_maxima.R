library(data.table)
library(zoo)  # For rollmean

# Example data creation
set.seed(123)
data <- data.table(
  chr = rep(letters[1:3], each = 100),
  location = rep(1:100, times = 3),
  value = rnorm(300)
)

# Compute rolling mean
data[, roll_median_int := rollmean(value, k = 5, fill = NA, align = "center"), by = chr]

# Function to find local maxima
find_local_maxima <- function(x) {
  # Shift data to get neighbors
  shift_lag1 <- shift(x, 1, type = "lag")
  shift_lead1 <- shift(x, 1, type = "lead")
  
  # Identify local maxima
  local_maxima <- (x > shift_lag1) & (x > shift_lead1)
  
  return(local_maxima)
}

# Apply the function to find local maxima in rolling mean
data[, local_maxima := find_local_maxima(roll_median_int), by = chr]

# Filter the data to show only local maxima
local_maxima_data <- data[local_maxima == TRUE]

# Display the local maxima data
print(local_maxima_data)





# p value distributions

p <- ggplot(data_samp[data_samp$V4 > 1e-30], aes(x = V4)) +
  geom_histogram(binwidth = 5, fill = "blue", color="black") +
  scale_x_log10() +
  labs(
    title = "Histogram of p-values Distribution",
    x = "p-values",
    y = "Frequency"
  ) +
  theme_minimal()

# Print the plot
print(p)


