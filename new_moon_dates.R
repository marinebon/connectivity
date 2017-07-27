#NEW SIDE OF THE MOON

library(lunar)

#vector of moon dates to check if new moons
new_moons = c("2010-01-14", "2010-10-07", "2010-04-13", "2010-07-11", "2011-01-04", "2011-10-26", "2011-04-02", "2011-07-29", "2009-01-25", "2009-10-17", "2009-04-24", "2009-07-21")

lunar.phase(as.Date(new_moons, shift = 0, name = FALSE))

#lunar.illumination(as.Date(new_moons)) illumination of zero - new moon? 
