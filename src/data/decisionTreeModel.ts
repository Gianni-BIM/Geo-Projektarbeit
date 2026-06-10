import { TreeNode, SoilPoint } from '../types';

export const treeStructure: TreeNode = {
  id: 'root',
  name: 'Regenniveau-Verzweigung',
  rule: 'rain_mmsqm_mean_1995_2024 <= 783.425',
  meanShi: 3.126,
  sampleCount: 2411,
  squared_error: 0.199,
  isLeaf: false,
  x: 500,
  y: 35,
  children: [
    {
      id: 'cool_europe',
      name: 'Niederschlag <= 783.425 mm',
      rule: 'land_cover_Cropland <= 0.5',
      meanShi: 3.033,
      sampleCount: 1811,
      squared_error: 0.165,
      isLeaf: false,
      parentId: 'root',
      x: 250,
      y: 130,
      children: [
        {
          id: 'cool_dry',
          name: 'Landbedeckung: Cropland <= 0.5',
          rule: 'land_use_Fallow land <= 0.5',
          meanShi: 3.145,
          sampleCount: 1120,
          squared_error: 0.115,
          isLeaf: false,
          parentId: 'cool_europe',
          x: 125,
          y: 230,
          children: [
            {
              id: 'leaf_1',
              name: 'Nicht-Brachfläche',
              rule: 'land_use_Forestry <= 0.5',
              meanShi: 3.242,
              sampleCount: 820,
              squared_error: 0.082,
              isLeaf: true,
              parentId: 'cool_dry',
              x: 62,
              y: 345,
            },
            {
              id: 'leaf_2',
              name: 'Brachfläche Sektor',
              rule: 'land_cover_Bareland <= 0.5',
              meanShi: 2.721,
              sampleCount: 300,
              squared_error: 0.065,
              isLeaf: true,
              parentId: 'cool_dry',
              x: 187,
              y: 345,
            }
          ]
        },
        {
          id: 'cool_wet',
          name: 'Landbedeckung: Cropland > 0.5',
          rule: 'climate_name_BSk Arid, steppe, cold <= 0.5',
          meanShi: 2.852,
          sampleCount: 691,
          squared_error: 0.108,
          isLeaf: false,
          parentId: 'cool_europe',
          x: 375,
          y: 230,
          children: [
            {
              id: 'leaf_3',
              name: 'Ackerland (Nicht-BSk)',
              rule: 'climate_name_Csb <= 0.5',
              meanShi: 2.718,
              sampleCount: 391,
              squared_error: 0.054,
              isLeaf: true,
              parentId: 'cool_wet',
              x: 312,
              y: 345,
            },
            {
              id: 'leaf_4',
              name: 'Ackerland (BSk Steppe)',
              rule: 'temp_c_mean_1995_2024 <= 15.71',
              meanShi: 3.025,
              sampleCount: 300,
              squared_error: 0.071,
              isLeaf: true,
              parentId: 'cool_wet',
              x: 437,
              y: 345,
            }
          ]
        }
      ]
    },
    {
      id: 'warm_europe',
      name: 'Niederschlag > 783.425 mm',
      rule: 'rain_mmsqm_mean_1995_2024 <= 1010.335',
      meanShi: 3.408,
      sampleCount: 600,
      squared_error: 0.155,
      isLeaf: false,
      parentId: 'root',
      x: 750,
      y: 130,
      children: [
        {
          id: 'warm_agri',
          name: 'Niederschlag <= 1010.335 mm',
          rule: 'land_cover_Cropland <= 0.5',
          meanShi: 3.321,
          sampleCount: 420,
          squared_error: 0.098,
          isLeaf: false,
          parentId: 'warm_europe',
          x: 625,
          y: 230,
          children: [
            {
              id: 'leaf_5',
              name: 'Nicht-Ackerland (Moderater Regen)',
              rule: 'temp_c_mean_1995_2024 <= 14.055',
              meanShi: 3.214,
              sampleCount: 180,
              squared_error: 0.045,
              isLeaf: true,
              parentId: 'warm_agri',
              x: 562,
              y: 345,
            },
            {
              id: 'leaf_6',
              name: 'Ackerland (Moderater Regen)',
              rule: 'climate_name_Csb <= 0.5',
              meanShi: 3.551,
              sampleCount: 240,
              squared_error: 0.052,
              isLeaf: true,
              parentId: 'warm_agri',
              x: 687,
              y: 345,
            }
          ]
        },
        {
          id: 'warm_natural',
          name: 'Niederschlag > 1010.335 mm',
          rule: 'height_m <= 839.67',
          meanShi: 3.512,
          sampleCount: 180,
          squared_error: 0.089,
          isLeaf: false,
          parentId: 'warm_europe',
          x: 875,
          y: 230,
          children: [
            {
              id: 'leaf_7',
              name: 'Untere Lagen (Sehr Nass)',
              rule: 'climate_name_Cfa <= 0.5',
              meanShi: 3.255,
              sampleCount: 100,
              squared_error: 0.042,
              isLeaf: true,
              parentId: 'warm_natural',
              x: 812,
              y: 345,
            },
            {
              id: 'leaf_8',
              name: 'Höhenlagen (Sehr Nass)',
              rule: 'rain_mmsqm_mean_1995_2024 <= 1214.65',
              meanShi: 3.645,
              sampleCount: 80,
              squared_error: 0.038,
              isLeaf: true,
              parentId: 'warm_natural',
              x: 937,
              y: 345,
            }
          ]
        }
      ]
    }
  ]
};

// Map each point to its appropriate leaf ID deterministically based on tree splits
export function getLeafNodeIdForPoint(p: SoilPoint): string {
  if (p.rain_mmsqm_mean_1995_2024 <= 783.425) {
    // Left: Rain <= 783.425
    const isCropland = p.land_cover.toLowerCase().includes('cropland');
    if (!isCropland) {
      // Left-Left: Cropland <= 0.5 (True)
      const isFallow = p.land_use.toLowerCase().includes('fallow');
      if (!isFallow) {
        // Left-Left-Left: Fallow land <= 0.5 (True) -> leaf 1
        return 'leaf_1';
      } else {
        // Left-Left-Right: Fallow land <= 0.5 (False) -> leaf 2
        return 'leaf_2';
      }
    } else {
      // Left-Right: Cropland <= 0.5 (False, i.e., is Cropland)
      const isBSk = p.climate_name.toLowerCase().includes('bsk') || p.kg_climate_class === 7;
      if (!isBSk) {
        // Left-Right-Left: BSk <= 0.5 (True) -> leaf 3
        return 'leaf_3';
      } else {
        // Left-Right-Right: BSk <= 0.5 (False, i.e., is BSk) -> leaf 4
        return 'leaf_4';
      }
    }
  } else {
    // Right: Rain > 783.425
    if (p.rain_mmsqm_mean_1995_2024 <= 1010.335) {
      // Right-Left: Rain <= 1010.335
      const isCropland = p.land_cover.toLowerCase().includes('cropland');
      if (!isCropland) {
        // Right-Left-Left: Cropland <= 0.5 (True) -> leaf 5
        return 'leaf_5';
      } else {
        // Right-Left-Right: Cropland <= 0.5 (False, is Cropland) -> leaf 6
        return 'leaf_6';
      }
    } else {
      // Right-Right: Rain > 1010.335
      if (p.height_m <= 839.67) {
        // Right-Right-Left: Height <= 839.67 -> leaf 7
        return 'leaf_7';
      } else {
        // Right-Right-Right: Height > 839.67 -> leaf 8
        return 'leaf_8';
      }
    }
  }
}

// Check if a point belongs to a specific parent/sub-node or leaf node in the tree hierarchy
export function isPointInNode(p: SoilPoint, nodeId: string): boolean {
  if (nodeId === 'root') return true;

  const leafId = getLeafNodeIdForPoint(p);
  if (nodeId.startsWith('leaf_')) {
    return leafId === nodeId;
  }

  // Hierarchy checking
  switch (nodeId) {
    case 'cool_europe':
      return ['leaf_1', 'leaf_2', 'leaf_3', 'leaf_4'].includes(leafId);
    case 'warm_europe':
      return ['leaf_5', 'leaf_6', 'leaf_7', 'leaf_8'].includes(leafId);
    case 'cool_dry':
      return ['leaf_1', 'leaf_2'].includes(leafId);
    case 'cool_wet':
      return ['leaf_3', 'leaf_4'].includes(leafId);
    case 'warm_agri':
      return ['leaf_5', 'leaf_6'].includes(leafId);
    case 'warm_natural':
      return ['leaf_7', 'leaf_8'].includes(leafId);
    default:
      return false;
  }
}

// Find path from root to target node
export function getDecisionPath(tree: TreeNode, targetId: string): TreeNode[] | null {
  if (tree.id === targetId) return [tree];
  
  if (tree.children) {
    for (const child of tree.children) {
      const path = getDecisionPath(child, targetId);
      if (path) {
        return [tree, ...path];
      }
    }
  }
  return null;
}
