import { useEffect, useRef, useMemo } from 'react';
import L from 'leaflet';
import 'leaflet/dist/leaflet.css';
import { SoilPoint } from '../types';

interface SoilMapProps {
  filteredPoints: SoilPoint[];
  colorBy: 'SHI' | 'land_use' | 'land_cover' | 'climate_name';
  selectedPointId: number | null;
  onSelectPoint: (pointId: number | null) => void;
  onColorByChange: (mode: 'SHI' | 'land_use' | 'land_cover' | 'climate_name') => void;
}

// Fixed color set for categories to maintain aesthetic styling consistency
const CATEGORY_COLORS: Record<string, string> = {
  // Land Cover
  'Grassland': '#10b981',       // Emerald
  'Woodland': '#059669',        // Dark Emerald
  'Cropland': '#f59e0b',        // Amber
  'Shrubland': '#84cc16',       // Lime
  'Bareland': '#78716c',        // Stone
  
  // Land Use
  'Agriculture (excluding fallow land and kitchen gardens)': '#ec4899', // Pink
  'Forestry': '#14b8a6',                                                // Teal
  'Semi-natural and natural areas not in use': '#a855f7',               // Purple
  'Fallow land': '#f97316',                                             // Orange
  
  // Climate Name
  'Cfb Temperate no dry season warm': '#3b82f6',                        // Blue
  'Dfb Cold no dry season warm': '#06b6d4',                             // Cyan
  'Cfa Temperate no dry season hot': '#ef4444',                         // Red
  'Csb Temperate dry summer warm': '#f43f5e',                           // Rose
  'Csa Temperate dry summer hot': '#f59e0b',                            // Amber
  'Dfc Cold no dry season cold': '#6366f1',                             // Indigo
  'Dfa Cold no dry season hot': '#10b981',                              // Emerald
  'BSh Arid steppe hot': '#84cc16',                                     // Lime
  'BSk Arid steppe cold': '#0d9488',                                    // Dark Teal
  'Dsb Cold dry summer warm': '#8b5cf6',                                // Violet
};

export function stringToColor(str: string): string {
  let hash = 0;
  for (let i = 0; i < str.length; i++) {
    hash = str.charCodeAt(i) + ((hash << 5) - hash);
  }
  const h = Math.abs(hash) % 360;
  const s = 65 + (Math.abs(hash >> 8) % 25); // 65-90%
  const l = 40 + (Math.abs(hash >> 16) % 15); // 40-55%
  return `hsl(${h}, ${s}%, ${l}%)`;
}

export function getPointColor(point: SoilPoint, colorBy: 'SHI' | 'land_use' | 'land_cover' | 'climate_name'): string {
  if (colorBy === 'SHI') {
    const val = point.SHI;
    if (val >= 3.8) return '#0c4e54'; // Excellent (Deep Dark Teal)
    if (val >= 3.5) return '#27848b'; // Good (Teal)
    if (val >= 3.2) return '#68a9ae'; // Moderate (Light Teal)
    if (val >= 2.9) return '#d19900'; // Fair (Amber)
    return '#b91c1c'; // Critical (Crimson Red)
  }

  const categoryValue = point[colorBy];
  if (!categoryValue) return '#64748b';
  return CATEGORY_COLORS[categoryValue] || stringToColor(String(categoryValue));
}

export default function SoilMap({
  filteredPoints,
  colorBy,
  selectedPointId,
  onSelectPoint,
  onColorByChange,
}: SoilMapProps) {
  const mapContainerRef = useRef<HTMLDivElement>(null);
  const mapRef = useRef<L.Map | null>(null);
  const markersGroupRef = useRef<L.FeatureGroup | null>(null);

  // Generate legend items depending on colorBy Selection
  const legendItems = useMemo(() => {
    if (colorBy === 'SHI') {
      return [
        { label: 'Exzellent (≥ 3.8)', color: '#0c4e54' },
        { label: 'Sehr Gut (≥ 3.5)', color: '#27848b' },
        { label: 'Moderat (≥ 3.2)', color: '#68a9ae' },
        { label: 'Mäßig (≥ 2.9)', color: '#d19900' },
        { label: 'Kritisch (< 2.9)', color: '#b91c1c' },
      ];
    } else if (colorBy === 'land_cover') {
      return [
        { label: 'Wiese (Grassland)', color: '#10b981' },
        { label: 'Wald (Woodland)', color: '#059669' },
        { label: 'Ackerland (Cropland)', color: '#f59e0b' },
        { label: 'Strauchland (Shrubland)', color: '#84cc16' },
        { label: 'Kargland (Bareland)', color: '#78716c' },
      ];
    } else if (colorBy === 'land_use') {
      return [
        { label: 'Ackerbau Sektor', color: '#ec4899' },
        { label: 'Forstwirtschaft', color: '#14b8a6' },
        { label: 'Naturbelassene Zonen', color: '#a855f7' },
        { label: 'Brachfläche', color: '#f97316' },
      ];
    } else { // climate_name
      return [
        { label: 'Cfb Seeklima', color: '#3b82f6' },
        { label: 'Dfb Kontinentalklima', color: '#06b6d4' },
        { label: 'Cfa Subtropisch-Heiß', color: '#ef4444' },
        { label: 'Csb Warmes Mittelmeer', color: '#f43f5e' },
        { label: 'Csa Heißes Mittelmeer', color: '#f59e0b' },
        { label: 'Dfc Subpolar-Kalt', color: '#6366f1' },
        { label: 'Halbarid Kalt (BSk)', color: '#0d9488' },
        { label: 'Dsb Kontinental-Sommer', color: '#8b5cf6' },
      ];
    }
  }, [colorBy]);

  // Initialize Map instance
  useEffect(() => {
    if (!mapContainerRef.current || mapRef.current) return;

    // Use the standard high-performance SVG vector renderer to prevent any Canvas context clearRect errors
    const leafletMap = L.map(mapContainerRef.current, {
      preferCanvas: false,
      zoomControl: true,
      attributionControl: true,
    }).setView([47.5, 12.0], 4); // Centered over Europe

    // Add high contrast elegant light tile layout from CartoDB (clean and professional)
    L.tileLayer('https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png', {
      attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors &copy; <a href="https://carto.com/attributions">CARTO</a>',
      subdomains: 'abcd',
      maxZoom: 20
    }).addTo(leafletMap);

    const markersGroup = L.featureGroup().addTo(leafletMap);
    markersGroupRef.current = markersGroup;
    mapRef.current = leafletMap;

    return () => {
      if (mapRef.current) {
        mapRef.current.remove();
        mapRef.current = null;
      }
    };
  }, []);

  // Update Points and Markers on Map
  useEffect(() => {
    const leafletMap = mapRef.current;
    const markersGroup = markersGroupRef.current;
    if (!leafletMap || !markersGroup) return;

    markersGroup.clearLayers();

    // Loop through all points and render as performant vector circle markers
    filteredPoints.forEach((point) => {
      const isSelected = point.POINT_ID === selectedPointId;
      const markerColor = getPointColor(point, colorBy);

      const marker = L.circleMarker([point.lat_y, point.lon_x], {
        radius: isSelected ? 9 : 5.8,
        weight: isSelected ? 3.5 : 1,
        color: isSelected ? '#4f46e5' : '#ffffff', // Highlight border for selected
        fillColor: markerColor,
        fillOpacity: isSelected ? 0.95 : 0.82,
      });

      // Bind interactive HTML popup detailing chemical constraints and features
      const coverColor = CATEGORY_COLORS[point.land_cover] || '#1e293b';
      const useColor = CATEGORY_COLORS[point.land_use] || '#1e293b';
      const climateColor = CATEGORY_COLORS[point.climate_name] || '#475569';

      const popupContent = `
        <div class="p-1 px-1.5 font-sans min-w-[220px] select-none text-[11px] leading-relaxed">
          <div class="flex justify-between items-center border-b border-slate-100 pb-1.5 mb-1.5">
            <span class="font-mono text-[9px] font-bold text-slate-400">ID: ${point.POINT_ID}</span>
            <span class="bg-indigo-50 text-indigo-700 px-1.5 py-0.5 rounded font-bold">SHI: ${point.SHI.toFixed(2)}</span>
          </div>
          <div class="space-y-1 text-slate-600">
            <div><strong class="text-slate-800">Bedeckung:</strong> <span style="color: ${coverColor}; font-weight: bold;">${point.land_cover}</span></div>
            <div><strong class="text-slate-800">Nutzung:</strong> <span style="color: ${useColor}; font-weight: bold;">${point.land_use}</span></div>
            <div><strong class="text-slate-800">Klima:</strong> <span style="color: ${climateColor}; font-weight: bold;">${point.climate_name}</span></div>
            <div class="flex justify-between mt-1 text-[10px] font-mono border-t border-slate-100 pt-1">
              <span style="color: #059669; font-weight: bold;"> ${point.rain_mmsqm_mean_1995_2024.toFixed(0)} mm</span>
              <span style="color: #0284c7; font-weight: bold;"> ${point.temp_c_mean_1995_2024.toFixed(1)} °C</span>
              <span style="color: #6366f1; font-weight: bold;"> ${point.height_m.toFixed(0)} m</span>
            </div>
          </div>
        </div>
      `;

      marker.bindPopup(popupContent, {
        closeButton: true,
        className: 'custom-soil-popup'
      });

      // Point click listener to trigger active table highlighting
      marker.on('click', () => {
        onSelectPoint(point.POINT_ID);
      });

      markersGroup.addLayer(marker);
    });

    // Auto zoom map boundary to include all points with smooth padding
    if (filteredPoints.length > 0) {
      try {
        const bounds = L.latLngBounds(filteredPoints.map(d => [d.lat_y, d.lon_x]));
        leafletMap.fitBounds(bounds.pad(0.06), { animate: true, duration: 1.2 });
      } catch (err) {
        console.warn("Could not fit bounds of map markers:", err);
      }
    }
  }, [filteredPoints, colorBy, selectedPointId, onSelectPoint]);

  return (
    <div className="relative w-full h-full rounded-2xl overflow-hidden border border-slate-200 shadow-inner bg-slate-50">
      <div ref={mapContainerRef} className="absolute inset-0 z-0 h-full w-full" />
      
      <div className="absolute top-3 left-3 z-[400] rounded-2xl border border-slate-200 bg-white/95 p-2 shadow-md backdrop-blur-md">
        <div className="text-[8px] font-extrabold uppercase tracking-[0.25em] text-slate-400">Ziel - und Einflussvariablen</div>
        <div className="mt-1 flex flex-wrap gap-1.5">
          {([
            ['SHI', 'SHI'],
            ['land_cover', 'Bedeckung'],
            ['land_use', 'Nutzung'],
            ['climate_name', 'Klima'],
          ] as const).map(([mode, label]) => (
            <button
              key={mode}
              type="button"
              onClick={() => onColorByChange(mode)}
              className={`rounded-full border px-2.5 py-1 text-[9px] font-semibold transition ${colorBy === mode ? 'border-indigo-300 bg-indigo-50 text-indigo-800' : 'border-slate-200 bg-white text-slate-600 hover:border-slate-300 hover:bg-slate-50'}`}
            >
              {label}
            </button>
          ))}
        </div>
      </div>

      {/* Dynamic floating Map Legend Card Overlay */}
      <div className="absolute bottom-3 left-3 bg-white/95 backdrop-blur-md border border-slate-200/80 shadow-md p-2.5 rounded-2xl z-[400] max-w-[200px] select-none text-[9.5px]">
        <div className="font-extrabold text-slate-800 text-[8.5px] uppercase border-b border-slate-100 pb-1 mb-1.5 leading-none">
          {colorBy === 'SHI' ? 'Bodengüte (SHI)' : (colorBy === 'land_cover' ? 'Bodenbedeckung (LUCAS)' : (colorBy === 'land_use' ? 'Bodennutzung' : 'Klimaklassifikation'))}
        </div>
        <div className="space-y-1 max-h-[120px] overflow-y-auto pr-1">
          {legendItems.map((item, idx) => (
            <div key={idx} className="flex items-center gap-1.5">
              <span 
                className="w-2.5 h-2.5 rounded-full border border-white shrink-0 shadow-xs" 
                style={{ backgroundColor: item.color }}
              />
              <span className="text-slate-600 font-medium truncate leading-none" title={item.label}>
                {item.label}
              </span>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}
