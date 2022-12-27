# Tutorial 1: Introduction to R & RStudio

# The first part of this script will take you through some basic functions in R to clean and visualize data found in comma separated value (CSV) files. We will primarily be using a suite of packages found in the "tidyverse". We'll be reading in a messy CSV sheet, cleaning it up in preparation for future data analysis and visualization (that will be part 2 of this tutorial).

# We will be working with some species annotation data from NOAA Ocean Exploratio's Windows to the Deep 2019 Expedition (Cruise Number: EX1903).

# More information on this cruise can be found here: 
# https://oceanexplorer.noaa.gov/okeanos/explorations/ex1903/welcome.html

# ---------------------

# how to install a package onto your computer
# run this piece of code in the Console below, remove the "#" before running. You only need to install a package one time. 
# install.packages("tidyverse")
# install.packages("readxl") # this package is used to read in messy Excel sheets
# install.packages("writexl") # this package is used to write out Excel sheets
# install.packages("broom") # this package is used to clean up the output of statistical tests

# ---------------------

# how to load packages into R 
# you need to do this every time you want to use a package in R 
library(tidyverse) 
library(readxl)
library(writexl)
library(broom)

# ---------------------

# how to define your working directory 

# It's important to make sure that you keep all of your documents and scripts organized in a particular folder structure.
# This is my working directory, so you'll want to change it to the place where your data live. 

# Here is the function to tell you what your current working directory is: 
getwd()

# set your working directory 
# make sure you either use a double backslash "\\" or a forward slash "/"
wd <- "C:/Users/katharineegan/Documents/r_tutorial/ocean_exploration_data_tutorial"
setwd(wd)

# double check that your working directory is set
getwd()

# ---------------------

# how to read an excel sheet into R 
# I have a CSV that I'm going to read in. 

dive01_raw <- read_csv(file = "EX1903L2_ROV01_ANNOTATIONS_06Aug2020.csv")

# if you have an excel file you can use this function: 
#read_excel - .xlsx

# After running this function read_csv, you should see the object name (which we called "dive01_raw" pop up over in the upper left hand side of R, this is called the "Global Environment" )

# The CSV we just read into R is now called a "data frame" 
# You can check what the object is by using this function: 
class(dive01_raw)

# This is what should come up: 
# [1] "spec_tbl_df" "tbl_df"      "tbl"         "data.frame" 

# let's also read in a CSV from Dive 02
dive02_raw <- read_csv(file = "EX1903L2_ROV02_ANNOTATIONS_06Aug2020.csv")

# look at the class of Dive 02
class(dive02_raw)

# ---------------------

# Some basic data cleaning for data frames

# Now we are going to go through some basic functions to clean up the data frame "raw_data" using functions from the tidyverse package 

# A lot of the functions we will use to clean up the data frame will rely on knowing the names of the columns, which you can check here: 
names(dive01_raw)
names(dive02_raw)

# Both of these data frames should show you a list of 142 column names

# We are going to select a few columns to work with (because we don't need all of these data)

# Start a new data frame and work through cleaning up the data: 
# first we are going to combine the two data frames together into one data frame using a function called "bind_rows"
clean_data <- bind_rows(dive01_raw, dive02_raw) %>% 
  
  # this function selects the columns you want to work with. We are going to select the colunn that contains the name of the dive, the latitude and longitude recorded via a sensor on the remotely operated vehicle (ROV), the oxygen, temperature, salinity, and depth readings from the ROV, and the Phylum column
  
  select(c(`Dive Name`, 
           DEEPDISCOVERERNAV01_23975_Latitude, 
           DEEPDISCOVERERNAV01_23975_Longitude,
           SBECTD9PLUSDEEPDISCOVERER_23978_Depth,
           `SBECTD9PLUSDEEPDISCOVERER_23978_Oxygen Concentration`,
           `SBECTD9PLUSDEEPDISCOVERER_23978_Temperature`,
           `SBECTD9PLUSDEEPDISCOVERER_23978_Practical Salinity`,
           Phylum)) %>% 
  
  # Now let's rename these columns to something more practical and easier to work with. For the "rename" function, it's new name = old name:
  rename(dive_name = `Dive Name`,
         latitude = DEEPDISCOVERERNAV01_23975_Latitude,
         longitude = DEEPDISCOVERERNAV01_23975_Longitude, 
         depth = SBECTD9PLUSDEEPDISCOVERER_23978_Depth,
         oxygen = `SBECTD9PLUSDEEPDISCOVERER_23978_Oxygen Concentration`,
         temp = `SBECTD9PLUSDEEPDISCOVERER_23978_Temperature`, 
         salinity = `SBECTD9PLUSDEEPDISCOVERER_23978_Practical Salinity`,
         phylum = Phylum) %>% 
  
  # If you run this code thus far and click on "clean_data" in the global environment, you'll see that the data frame already looks a lot better and more readable! Let's finish cleaning it up. You can see that there are a lot of "NAs" in the Phylum column. We want to get rid of these, because there are no species recorded at these annotations, and for this example we only want annotations that were made of animals seen. You can remove NAs based on a column using this function: 
  drop_na(phylum) %>% 
  
  # The last thing I like to do when cleaning up a data frame is to strip the "white space" that could occur before or after a word. I generally do this within the text columns only.
  
  mutate(dive_name = str_trim(dive_name, c("both")),
         phylum = str_trim(phylum, c("both")))

# One last thing I like to do is to check what the "type" or "class" is of the columns in the data frames. It will be difficult to work with the data if say, the coordinates are character vectors and not numeric values.

# This function checks the class of each column in the data frame
sapply(clean_data, class)

#dive_name    latitude   longitude       depth      oxygen        temp    salinity 
#"character"   "numeric"   "numeric"   "numeric"   "numeric"   "numeric"   "numeric" 
#phylum 
#"character"  

# Looks like everything is in order! 

# ---------------------

# Summarizing data 

# The data frame is cleaned up and we are now ready to start summarizing and playing with the data. There are a number of ways you can do this. First, let's create a summary table that provides the mean, standard deviation, and standard error of the depth data for each phylum. You can also do this with the salinity, oxygen, and temperature data. You do that this way: 

depth_summary <- clean_data %>% 
  group_by(phylum, dive_name) %>% 
  summarize(mean = mean(depth),
            sd = sd(depth),
            count = length(depth),
            se = sd(depth)/sqrt(length(depth)))

# This data frame gives you the average, standard deviation, and standard error of the depth data for each phylum that was annotated on Dive01. 

# Now we are going to filter the data frame. Say you only want to look at one phlyum. You can easily filter that phylum out like this. Here were are filtering our all occurrences of "Porifera" which are sponges.  

sponges <- clean_data %>% 
  filter(phylum == "Porifera")

# You can also use filter() to filter out numbers that are > < or == to a specific number. 
# Filter can also be used backwards. let's say you want everything EXCEPT sponges. This code REMOVES all occurrences of "Porifera"

no_sponges <- clean_data %>% 
  filter(phylum != "Porifera")

# ---------------------

# OPTIONAL

# how to write out data frames to new Excel sheets or CSVs 

# Your data are cleaned up and now let's say you want to pull it into ArcGIS and create a shapefile out of it. Here's how you write your cleaned up data to a spreadsheet: 

# CSV: 
write_csv(clean_data, "EX1903L2_Dives_01_02_Clean_Annotations.csv")

# Excel sheet: 
write_xlsx(clean_data, "EX1903L2_Dives_01_02_Clean_Annotations.xlsx")

# ---------------------
# Tutorial 2: Using R & RStudio for Data Visualization and Analysis

# The second part of this script will take you through some basic functions in R to take cleaned up data for analysis and visualization. We will primarily be using a suite of packages found in the "tidyverse". We'll be using the same cleaned up data from earlier on in the script from EX1903. We will conduct exploratory data analysis and the visualize the data using ggplot2.

# Our hypothesis for the purposes of this tutorial: 
# The average depth for the Cnidaria annotations is different between Dives 1 and 2.

# ---------------------

# filter out the Cnidaria annotations from the "phylum" column in the "clean_data" data frame. Remember we are only looking at Cnidaria for our hypothesis testing
cnidaria <- clean_data %>% 
  filter(phylum == "Cnidaria")

# ---------------------

# EXPLORATORY DATA ANALYSIS IN R using ggplot2 

# ggplot2 is an R package that is loaded with the "tidyverse" suite of packges. It's used to make nice graphs.
# This website is a good place to go when you need the basic code to start making a graph. You can start adding to that base code from there: http://www.cookbook-r.com/Graphs/
# We're going to create a couple of graphs. 

# FIRST: Let's plot the density distribution of the depth data:
ggplot(cnidaria, aes(x = depth)) + 
  geom_density()

# We are also going to do a histogram of the data: 
ggplot(cnidaria, aes(x = depth)) +
  geom_histogram(binwidth = 2, colour = "black", fill = "white")

# What do these graphs tell us? 
# It looks like there is a high number of annotations of Cnidaria around 700 to 800 meters, but it also looks like some annotations were made in much shallower depths. By the looks of it - probably around 300 meters and 500 meters. What do you think we could hypothesize about the data based on these two graphs? Well, maybe Dive 1 and Dive 2 had very similar depth ranges in general. We also know that Cnidaria is a phylum that encompasses coral (which live on the seafloor) and also jellyfish (which live in the water column)

# Let's look at the average depth for the Cnidaria annotations between dives 1 and 2: 
cnidaria_summary <- cnidaria %>% 
  group_by(dive_name, phylum) %>% 
  summarize(mean_depth = mean(depth, na.rm = T), 
            sd_depth = sd(depth, na.rm = T),
            count = length(phylum), 
            se_depth = sd_depth/sqrt(count))

# Based on this summary, the average depth for the Cnidaria annotations looks pretty similar. However, the standard error is higher for Dive 2. Let's investigate further and look at the depth range of the annotations
cnidaria_summary <- cnidaria %>% 
  group_by(dive_name, phylum) %>% 
  summarize(mean_depth = mean(depth, na.rm = T), 
            sd_depth = sd(depth, na.rm = T),
            count = length(phylum), 
            se_depth = sd_depth/sqrt(count),
            max_depth = max(depth), 
            min_depth = min(depth))

# Minimum depth for Cnidaria annotations is around 300 meters - this should explain the high error bars.

# For the last part of our EDA - let's create a boxplot showing the depth distribution of the Cnidaria annotations between Dives 1 & 2 
ggplot(cnidaria, aes(x = dive_name, y = depth)) + 
  geom_boxplot()

# Woah! This boxplot is showing a lot of outliers. Looks like there were definitely Cnidaria annotations made in the water column.

# ---------------------

# Conduct your statistical test 
# Now we are going to conduct a t-test to see if there is a difference in the depth data for Cnidaria between Dives 1 and 2. We will be doing a two-tailed t-test because our hypothesis is: There is a difference in depth of the Cnidaria annotations between Dives 1 and 2. 

# let's look at the help for t.tests in R
?t.test

# We are going to use the "formula" argument for the t.test y ~ x. X is the independent variable, in this case that is the dive number. Y is the dependent variable, in this case, that is the depth.

# conduct the t-test: 
t <- t.test(depth ~ dive_name, data = cnidaria)
t

# on first look, it looks like the Cnidaria depth annotations are different from each other as the p value is < 0.05. Based on this we can say our hypothesis is true - there is a difference in the Cnidaria depth annotations between Dives 1 and 2.

# ---------------------

# Clean up the statistical test to write out as an Excel spreadsheet. This is where we are going to use the broom package you installed earlier. 
t_df <- broom::tidy(t)

# ---------------------

# OPTIONAL
# write out the statistical test to an excel spreadsheet for use later
# this is helpful if you'd like to make a table for a report or publication
write_xlsx(t_df, path = "cnidaria_ttest_results.xlsx")

# ---------------------

# Create the final figure that you'll use in your report or publication
# Let's make a box plot as that seems to represent the data best
ggplot(cnidaria, aes(x = dive_name, y = depth, fill = dive_name)) + 
  geom_boxplot() +
  labs(x = "Dive Number", y = "Depth (m)") +
  scale_fill_manual(values = c("#E69F00", "#56B4E9")) +
  scale_x_discrete(breaks = c("EX1903L2_Dive01", "EX1903L2_Dive02"),
                   labels = c("01", "02")) +
  theme_bw() +
  theme(legend.position = "none",
        axis.text = element_text(size = 12),
        axis.title = element_text(size = 14))

# ---------------------
# how to write out a plot as a jpeg
# then save it
ggsave("boxplot_cnidaria_depth.jpeg", width = 6, height = 3, 
       units = "in")
