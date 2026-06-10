export interface SoilPoint {
  X: number;
  Y: number;
  POINT_ID: number;
  SHI: number;
  height_m: number;
  temp_c_mean_1995_2024: number;
  rain_mmsqm_mean_1995_2024: number;
  land_use: string;
  land_cover: string;
  lon_x: number;
  lat_y: number;
  kg_climate_class: number;
  climate_name: string;
  // Predictions for Random Forest Evaluation (residuals, prediction columns simulated from the model)
  pred_shi?: number;
}

export interface TreeNode {
  id: string;
  name: string;
  rule: string;
  meanShi: number;
  sampleCount: number;
  isLeaf: boolean;
  children?: TreeNode[];
  parentId?: string;
  x: number;
  y: number;
  squared_error?: number;
  value?: number;
}

export interface MetricCardValue {
  label: string;
  value: string | number;
  description?: string;
}
