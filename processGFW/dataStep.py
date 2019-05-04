'''The following code processes GFW_point data as follows:

    1. Subset Patagonia shelf
    2. Create time stamp data
    3. Merge in GFW_public data
    4. Get unique MMSI ships for each day and save
    5. Organize columns
    
    Patagonia shelf coordinates:
        lower left lat: -58
        lower left lon: -77
        upper right lat: -23
        upper right lon: -22
    
    Columns: 
    
    [['timestamp', 'year', 'month', 'day', 'hour', 'minute', 'second', 'mmsi', 'lat', 'lon', \
      'segment_id', 'message_id', 'type', 'speed', 'course', 'heading', 'shipname', 'callsign', \
      'destination', 'elevation_m', 'distance_from_shore_m', 'distance_from_port_m', 'nnet_score', \
      'logistic_score', 'flag', 'geartype', 'length', 'tonnage', 'engine_power', 'active_2012', \
      'active_2013', 'active_2014', 'active_2015', 'active_2016']]
'''                     

                    
import pandas as pd
import numpy as np
import feather
import os as os
import glob
from joblib import Parallel, delayed
import multiprocessing
import gc
from datetime import datetime, timedelta
import sys

# CONSTANTS
GFW_DIR = '/data2/GFW_point/'
GFW_OUT_DIR_CSV = '/home/server/pi/homes/woodilla/Data/GFW_point/Patagonia_Shelf/csv/'
GFW_OUT_DIR_FEATHER = '/home/server/pi/homes/woodilla/Data/GFW_point/Patagonia_Shelf/feather/'
OUTPUT_DIR = ''
NUM_CORES = 5
MAX_SPEED = 20

class dataStep():
    def __init__(self, csv_out_dir, feather_out_dir, lon1, lon2, lat1, lat2, parallel=True):
    # x, y, n_trees, n_features, sample_sz, depth=10, min_leaf=5):
        # x: independent variables
        # y: dependent variable
        # n_trees: number of uncorrelated trees to ensemble
        # n_features: number of features to sample and pass onto each tree
        # sample_size: number of rows randomly selected and passed to each tree.
        # depth: depth of each decision tree (splits).
        # min_leaf: min number of rows required in a node to cause further split

        # Constants
        GFW_DIR = '/data2/GFW_point/'
        GFW_OUT_DIR_CSV = self.csv_out_dir
        GFW_OUT_DIR_FEATHER = feather_out_dir
        
        # Initial error checking
        f = os.path.isdir(csv_out_dir)
        g = os.path.isdir(feather_out_dir)

        if f | g is False:
            print("Output folder does not exist. Exiting...")
            sys.exit(1)

        print("Processing Global Fish Watch raw data")
        print("-------------------------------------")
        print(f"Processed files with be stored in: ", {GFW_OUT_DIR_FEATHER})
        print("[1/5] Setting parameters")

        # Max speed of vessels to filter out
        MAX_SPEED  = 32      # 20 MPH or 32.1869 KPH

        self.lon1, self.lon2, self.lat1, self.lat2 = lon1, lon2, lat1, lat2
        self.parallel = parallel
        self.csv_out_dir = csv_out_dir
        self.feather_out_dir = feather_out_dir

    # def calc_fishing_effort(dat):
    #     timedat = dat.sort_values('timestamp')
    #     t1 = timedat.timestamp.iloc[0]
    #     t2 = timedat.timestamp.iloc[-1]    
        
    #     t1 = datetime.strptime(t1, "%Y-%m-%d %H:%M:%S UTC")
    #     t2 = datetime.strptime(t2, "%Y-%m-%d %H:%M:%S UTC")
    #     tdiff = abs(t2 - t1)
    #     tdiff = round(tdiff.seconds/60/60, 2)
    #     return tdiff

    def spherical_dist_populate(lat_lis, lon_lis, r=6371):
        """
        Calculate spherical distance (km) for list of lat/lon

        Args:
            lat_lis: list of latitude locations
            lon_lis: list of longitude locations
            r: radius of the Earth (3959 miles & 6371 km) 

        Returns:
            pairwise distance matrix
        """
        
        

        lat_mtx = np.array([lat_lis]).T * np.pi / 180
        lon_mtx = np.array([lon_lis]).T * np.pi / 180

        cos_lat_i = np.cos(lat_mtx)
        cos_lat_j = np.cos(lat_mtx)
        cos_lat_J = np.repeat(cos_lat_j, len(lat_mtx), axis=1).T

        lat_Mtx = np.repeat(lat_mtx, len(lat_mtx), axis=1).T
        cos_lat_d = np.cos(lat_mtx - lat_Mtx)

        lon_Mtx = np.repeat(lon_mtx, len(lon_mtx), axis=1).T
        cos_lon_d = np.cos(lon_mtx - lon_Mtx)

        mtx = r * np.arccos(cos_lat_d - cos_lat_i*cos_lat_J*(1 - cos_lon_d))
        return mtx

    def GFW_directories():
        """ Get GFW directory list """
        
        dirs = os.listdir(GFW_DIR)
        # Remove subfolders 'BK' and 'identities'
        if 'BK' in dirs:
            dirs.remove('BK')
        
        if 'identities' in dirs:
            dirs.remove('identities')
        
        return dirs

    def calc_kph(data):
        """
        Calculate kph

        Args:
            data: DataFrame with lat and lon

        Returns:
            Processed DataFrame
        """

        # Calculate distance traveled
        data = data.sort_values('timestamp')
        fobs_lat = data['lat'].iat[0]
        fobs_lon = data['lon'].iat[0]
        lat_lag = data['lat'].shift(1, fill_value=fobs_lat)
        lon_lag = data['lon'].shift(1, fill_value=fobs_lon)
        lat = data['lat'].values
        lon = data['lon'].values
        
        tlag = data['timestamp'].shift(1, fill_value=data['timestamp'].iat[0])
        
        outvalues = pd.Series()
        outvalues2 = pd.Series()
        for i in range(len(data)):
            # Calculate distance
            lat1 = lat_lag.iat[i]
            lat2 = lat[i]
            lon1 = lon_lag.iat[i]
            lon2 = lon[i]
            d = pd.Series(round(spherical_dist_populate([lat1, lat2], [lon1, lon2] )[0][1], 2))
            outvalues = outvalues.append(d, ignore_index=True)
            
            # Calculate travel time
            t1 = data.timestamp.iat[i]
            t2 = tlag.iat[i]   
            
            t1 = datetime.strptime(t1, "%Y-%m-%d %H:%M:%S UTC")
            t2 = datetime.strptime(t2, "%Y-%m-%d %H:%M:%S UTC")
        
            tdiff = abs(t2 - t1)
            tdiff = pd.Series(round(tdiff.seconds/60/60, 4))
            outvalues2 = outvalues2.append(tdiff)
            
        data['dist'] = outvalues.values
        data['travel_time'] = outvalues2.values   
        data['kph'] = data['dist']/data['travel_time'] 
        data['kph'] = np.where(data['travel_time'] == 0, 0, data['kph'])

        return data


    def process(data): 
        """
        Process data

        Args:
            data: DataFrame to process

        Returns:
            DataFrame with kph
        """
        
      
        # (1) Subset Region
        retdat = data[(data['lon'] >= self.lon1) & (data['lon'] <= self.lon2)] 
        retdat = retdat[(retdat['lat'] >= self.lat1) & (retdat['lat'] <= self.lat2)]
        
        # Get list of all vessels in region
        unique_vessels = list(retdat['mmsi'].unique())

        # Subset to allow for all segments even if outside of range
        retdat = data[data['mmsi'].isin(unique_vessels)]
        
        # (2) Remove boats on land and at port
        retdat = retdat[retdat['distance_from_shore_m'] > 10]
        retdat = retdat[retdat['distance_from_port_m'] > 10]
        
        # (3) Remove inconsistent tracks due to spoofing or noisy data
        # Results from calc_speed_dist.py
        #    quant      value
        #0    0.10   0.000000
        #1    0.20   0.000000
        #2    0.30   0.000000
        #3    0.40   0.000000
        #4    0.50   0.100000
        #5    0.60   0.400000
        #6    0.70   4.900000
        #7    0.80   9.100000
        #8    0.90  12.400000
        #9    0.95  14.400000
        #10   0.96  15.200000
        #11   0.97  16.299999
        #12   0.98  17.700001
        #13   0.99  19.900000   MPH
        #     Max 1.00   
        

        
        # Gropuby mmsi and get distance and time between timestamps
        retdat = retdat.groupby('mmsi').apply(calc_kph).reset_index(drop=True)
        
        # Get max speed for each mmsi
        mmsi_kph = retdat.groupby('mmsi', as_index=False)['kph'].max()

        # Keep vessels travel less than 20kph
        mmsi_kph2 = mmsi_kph[mmsi_kph['kph'] <= self.MAX_SPEED]
        mmsi_keep = mmsi_kph2['mmsi'].unique()
        retdat = retdat[retdat['mmsi'].isin(mmsi_keep)]

    
        # (4) Determine if stationary where distance_traveled > 1
        retdat['stationary'] = np.where(retdat['dist'] > 1, 0, 1)
            
        # (6) In/Out of EEZ (country)
        
        # (7) Calculate daily fishing effort
        # Incomplete
        # Fishing or not to calculate fishing effort
        
        # group_time = retdat.groupby('mmsi').apply(calc_fishing_effort)
        #mdat = pd.DataFrame({'mmsi': group_time.index.values, 'daily_effort': group_time[:]})
        #mdat = mdat.rename_axis(None)
        # retdat = pd.merge(retdat, mdat, on="mmsi", how='left')
        
    #------------------------------------------------------------------------------

        # Separate Year, month, day, hour, minute, second
        retdat.loc[:, 'timestamp'] = pd.to_datetime(retdat['timestamp'], format="%Y-%m-%d %H:%M:%S UTC")
        retdat.loc[:, 'year'] = pd.DatetimeIndex(retdat['timestamp']).year 
        retdat.loc[:, 'month'] = pd.DatetimeIndex(retdat['timestamp']).month
        retdat.loc[:, 'day'] = pd.DatetimeIndex(retdat['timestamp']).day
        retdat.loc[:, 'hour'] = pd.DatetimeIndex(retdat['timestamp']).hour
        retdat.loc[:, 'minute'] = pd.DatetimeIndex(retdat['timestamp']).minute
        retdat.loc[:, 'second'] = pd.DatetimeIndex(retdat['timestamp']).second
        
        # Merge GFW ID data (incomplete)
        #retdat = pd.merge(retdat, gfw_vessel_dat, how='left', on='mmsi')
        
        # Organize columns
        # retdat = retdat[['timestamp', 'year', 'month', 'day', 'hour', 'minute', 'second', 'mmsi', 'lat', 'lon', \
        #                 'kph', 'dist', 'travel_time', 'stationary', \
        #                 'segment_id', 'message_id', 'type', 'speed', 'course', 'heading', 'shipname', 'callsign', \
        #                 'destination', 'elevation_m', 'distance_from_shore_m', 'distance_from_port_m', 'nnet_score', \
        #                 'logistic_score', 'flag', 'geartype', 'length', 'tonnage', 'engine_power', 'active_2012', \
        #                 'active_2013', 'active_2014', 'active_2015', 'active_2016']]
        
        return retdat

    def processGFW(i):
        '''Parallel function'''

        # Get subdirectory list of files
        subdir = GFW_DIR + i
        allFiles = glob.glob(subdir + "/*.csv")
        list_ = []

        if len(allFiles) > 0:
            # Append files in subdir
            for file_ in allFiles:
                df = pd.read_csv(file_, index_col=None, header=0)
                list_.append(df)
                dat = pd.concat(list_, axis = 0, ignore_index = True)

            # Append data
            outdat = data_step(data=dat)

            # Get string for filename from timestamp
            filename = f"{outdat['year'][1]}-" + f"{outdat['month'][1]}".zfill(2) + f"-" + f"{outdat['day'][1]}".zfill(2)

            # Save unique mmsi for each day
            # unique_mmsi_data = outdat['mmsi'].unique()
            # unique_mmsi = pd.DataFrame({'mmsi':unique_mmsi_data})
            # unique_mmsi.to_feather('~/Data/GFW_point/Patagonia_Shelf/vessel_list/' + filename +  '_vessel_list'  + '.feather')

            # Save data
            outdat.to_csv(f"{GFW_OUT_DIR_CSV}{filename}.csv", index=False)
            outdat.to_feather(f"{GFW_OUT_DIR_FEATHER}{filename}.feather")



""" # Main function
if __name__ == '__main__':

    gfw_list_dirs = sorted(GFW_directories())

    # Check for missing files
    # Get csv files from output
    # csv_files = glob.glob(GFW_OUT_DIR_CSV + "*.csv")
    # csv_files = [item.replace('/home/server/pi/homes/woodilla/Data/GFW_point/Patagonia_Shelf/csv/', '') for item in csv_files]
    # csv_files = [item.replace('.csv', '') for item in csv_files]

    # # Get feather files
    # feather_files = glob.glob(GFW_OUT_DIR_CSV + "*.csv")
    # feather_files = [item.replace('/home/server/pi/homes/woodilla/Data/GFW_point/Patagonia_Shelf/feather/', '') for item in feather_files]
    # feather_files = [item.replace('.csv', '') for item in feather_files]

    # # Compare csv and feather for differences
    # csv_feather_diff = list(set(csv_files).difference(feather_files))
    
    # # Compare output to GFW list
    # gfw_diff = list(set(gfw_list_dirs).difference(feather_files))

    # # Extend differences in csv and feather
    # gfw_diff.extend(csv_feather_diff)
    
    # # New gfw_list_dirs
    # gfw_list_dirs = gfw_diff
    
    # # Need to shift dates because previous date equals current date (wrong time stamp data)
    # new_gfw_list_dirs = []
    # for i in gfw_list_dirs:
    #     indate = i
    #     outdate = datetime.strptime(indate, "%Y-%m-%d")
    #     outdate = outdate + timedelta(days=-1)
    #     outdate = datetime.strftime(outdate, "%Y-%m-%d")
    #     new_gfw_list_dirs.append(outdate)
    
    # GFW Public Data
    #gfw_vessel_dat = pd.read_csv('~/Data/GFW_public/fishing_vessels/fishing_vessels.csv')

    pool = multiprocessing.Pool(NUM_CORES, maxtasksperchild=1)         
    #pool.start()
    pool.map(processGFW, gfw_list_dirs)
    pool.close()



'''The following code processes GFW_point data as follows:
    1. Subset Patagonia shelf
    2. Create time stamp data
    3. Merge in GFW_public data
    4. Get unique MMSI ships for each day and save
    5. Organize columns
    
    Patagonia shelf coordinates:
        lower left lat: -58
        lower left lon: -77
        upper right lat: -23
        upper right lon: -22
    
    Columns: 
    
    [['timestamp', 'year', 'month', 'day', 'hour', 'minute', 'second', 'mmsi', 'lat', 'lon', \
      'segment_id', 'message_id', 'type', 'speed', 'course', 'heading', 'shipname', 'callsign', \
      'destination', 'elevation_m', 'distance_from_shore_m', 'distance_from_port_m', 'nnet_score', \
      'logistic_score', 'flag', 'geartype', 'length', 'tonnage', 'engine_power', 'active_2012', \
      'active_2013', 'active_2014', 'active_2015', 'active_2016']]
'''             
 """


    
    # Calculate speed traveled
    #data = data.sort_values('timestamp')
    #tlag = data['timestamp'].shift(1, fill_value=data['timestamp'].iat[0])
    
    #outvalues2 = pd.Series()
    #for i in range(len(data)):
    #    t1 = data.timestamp.iat[i]
    #    t2 = tlag.iat[i]   
          
    #    t1 = datetime.strptime(t1, "%Y-%m-%d %H:%M:%S UTC")
    #    t2 = datetime.strptime(t2, "%Y-%m-%d %H:%M:%S UTC")
    
    #    tdiff = abs(t2 - t1)
    #    tdiff = pd.Series(round(tdiff.seconds/60/60, 4))
    #    outvalues = outvalues.append(tdiff)
    
    #data['travel_time'] = outvalues.values   
    #data['kph'] = data['dist']/data['travel_time'] 
    #data['kph'] = np.where(data['travel_time'] == 0, 0, data['kph'])

    #return data









    #if len(new_gfw_list_dirs) > 0:
    #    # Process data in parallel
    #    INPUTS = new_gfw_list_dirs
    #    #results = Parallel(n_jobs=NUM_CORES, verbose=10)(delayed(processGFW)(i) for i in INPUTS)
    #    #del results
    #    #print(results)

    #    pool = multiprocessing.Pool(NUM_CORES, maxtasksperchild=1)         
    #    #pool.start()
    #    pool.map(processGFW, INPUTS)
    #    pool.close()
    #else:
    #    print("All files have been processed.")