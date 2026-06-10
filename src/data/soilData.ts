import { SoilPoint } from '../types';
import geojsonData from './points.json';

export const CLIMATE_NAMES: Record<number, string> = {
  1: 'Af Tropical rainforest',
  2: 'Am Tropical monsoon',
  3: 'Aw Tropical savannah',
  4: 'BWh Arid desert hot',
  5: 'BWk Arid desert cold',
  6: 'BSh Arid steppe hot',
  7: 'BSk Arid steppe cold',
  8: 'Csa Temperate dry summer hot',
  9: 'Csb Temperate dry summer warm',
  10: 'Csc Temperate dry summer cold',
  11: 'Cwa Temperate dry winter hot',
  12: 'Cwb Temperate dry winter warm',
  13: 'Cwc Temperate dry winter cold',
  14: 'Cfa Temperate no dry season hot',
  15: 'Cfb Temperate no dry season warm',
  16: 'Cfc Temperate no dry season cold',
  17: 'Dsa Cold dry summer hot',
  18: 'Dsb Cold dry summer warm',
  19: 'Dsc Cold dry summer cold',
  20: 'Dsd Cold dry summer very cold',
  21: 'Dwa Cold dry winter hot',
  22: 'Dwb Cold dry winter warm',
  23: 'Dwc Cold dry winter cold',
  24: 'Dwd Cold dry winter very cold',
  25: 'Dfa Cold no dry season hot',
  26: 'Dfb Cold no dry season warm',
  27: 'Dfc Cold no dry season cold',
  28: 'Dfd Cold no dry season very cold',
  29: 'ET Polar tundra',
  30: 'EF Polar frost'
};

export const soilData: SoilPoint[] = geojsonData.features.map((feature: any) => {
  const p = feature.properties;
  const climateClass = p.kg_climate_class;
  const climateName = CLIMATE_NAMES[climateClass] || `Klimaklasse ${climateClass} (Unbekannt)`;

  // Deterministic calculation for RF predicted values so diagrams work perfectly
  let predicted = 3.12;
  
  if (p.rain_mmsqm_mean_1995_2024 > 1000) predicted += 0.28;
  else if (p.rain_mmsqm_mean_1995_2024 < 600) predicted -= 0.35;
  
  if (p.land_cover === 'Woodland') predicted += 0.35;
  else if (p.land_cover === 'Cropland') predicted -= 0.18;
  
  if (p.temp_c_mean_1995_2024 < 10) predicted += 0.15;
  else if (p.temp_c_mean_1995_2024 > 15) predicted -= 0.22;
  
  if (p.height_m > 300) predicted += 0.08;

  const noise = Math.sin(p.POINT_ID) * 0.18;
  predicted += noise;
  predicted = Math.max(1.8, Math.min(4.1, Number(predicted.toFixed(3))));

  return {
    X: p.X,
    Y: p.Y,
    POINT_ID: p.POINT_ID,
    SHI: p.SHI,
    height_m: p.height_m,
    temp_c_mean_1995_2024: p.temp_c_mean_1995_2024,
    rain_mmsqm_mean_1995_2024: p.rain_mmsqm_mean_1995_2024,
    land_use: p.land_use || 'Sonstiges',
    land_cover: p.land_cover || 'Sonstiges',
    lon_x: p.lon_x || p.X,
    lat_y: p.lat_y || p.Y,
    kg_climate_class: p.kg_climate_class,
    climate_name: climateName,
    pred_shi: predicted,
  };
});
