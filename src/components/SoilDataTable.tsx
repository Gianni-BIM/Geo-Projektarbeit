import { useState, useMemo } from 'react';
import { SoilPoint } from '../types';
import { Search, Loader2, ArrowUpDown, ChevronLeft, ChevronRight, Download, FilterX } from 'lucide-react';

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

function stringToColor(str: string): string {
  let hash = 0;
  for (let i = 0; i < str.length; i++) {
    hash = str.charCodeAt(i) + ((hash << 5) - hash);
  }
  const h = Math.abs(hash) % 360;
  return `hsl(${h}, 65%, 45%)`;
}

interface SoilDataTableProps {
  data: SoilPoint[];
  selectedPointId: number | null;
  onSelectPoint: (pointId: number | null) => void;
}

type SortField = 'POINT_ID' | 'SHI' | 'height_m' | 'temp_c_mean_1995_2024' | 'rain_mmsqm_mean_1995_2024' | 'land_cover' | 'land_use';
type SortOrder = 'asc' | 'desc';

export default function SoilDataTable({
  data,
  selectedPointId,
  onSelectPoint,
}: SoilDataTableProps) {
  const [searchTerm, setSearchTerm] = useState('');
  const [sortField, setSortField] = useState<SortField>('SHI');
  const [sortOrder, setSortOrder] = useState<SortOrder>('desc');
  const [currentPage, setCurrentPage] = useState(1);
  const [pageSize, setPageSize] = useState(10);

  // Reset pagination on filter or search term change
  const handleSearchChange = (term: string) => {
    setSearchTerm(term);
    setCurrentPage(1);
  };

  const handlePageSizeChange = (size: number) => {
    setPageSize(size);
    setCurrentPage(1);
  };

  // 1. Apply local search filtering on top of tree filters
  const searchedData = useMemo(() => {
    if (!searchTerm.trim()) return data;
    const term = searchTerm.toLowerCase();
    return data.filter(
      (p) =>
        p.POINT_ID.toString().includes(term) ||
        p.land_cover.toLowerCase().includes(term) ||
        p.land_use.toLowerCase().includes(term) ||
        p.climate_name.toLowerCase().includes(term)
    );
  }, [data, searchTerm]);

  // 2. Apply Column Sorting
  const sortedData = useMemo(() => {
    const list = [...searchedData];
    list.sort((a, b) => {
      let valA = a[sortField];
      let valB = b[sortField];

      if (typeof valA === 'string' && typeof valB === 'string') {
        return sortOrder === 'asc' 
          ? valA.localeCompare(valB) 
          : valB.localeCompare(valA);
      }

      // Numeric comparisons
      const numA = Number(valA || 0);
      const numB = Number(valB || 0);
      return sortOrder === 'asc' ? numA - numB : numB - numA;
    });
    return list;
  }, [searchedData, sortField, sortOrder]);

  // 3. Paginate Table Rows
  const totalRows = sortedData.length;
  const totalPages = Math.max(1, Math.ceil(totalRows / pageSize));
  
  const paginatedData = useMemo(() => {
    const startIdx = (currentPage - 1) * pageSize;
    return sortedData.slice(startIdx, startIdx + pageSize);
  }, [sortedData, currentPage, pageSize]);

  // Column header click sorter
  const handleSort = (field: SortField) => {
    if (sortField === field) {
      setSortOrder(sortOrder === 'asc' ? 'desc' : 'asc');
    } else {
      setSortField(field);
      setSortOrder('desc');
    }
    setCurrentPage(1);
  };

  // Convert current filtered dataset directly to raw CSV and trigger browser download
  const handleExportCSV = () => {
    if (!sortedData.length) return;
    
    const headers = ['POINT_ID', 'SHI', 'Pred_SHI', 'Elevation_m', 'Temp_°C', 'Precip_mm', 'Land_Cover', 'Land_Use', 'Climate_Class'];
    const rows = sortedData.map(p => [
      p.POINT_ID,
      p.SHI,
      p.pred_shi || p.SHI,
      p.height_m,
      p.temp_c_mean_1995_2024,
      p.rain_mmsqm_mean_1995_2024,
      `"${p.land_cover.replace(/"/g, '""')}"`,
      `"${p.land_use.replace(/"/g, '""')}"`,
      `"${p.climate_name.replace(/"/g, '""')}"`
    ]);

    const csvContent = [headers.join(','), ...rows.map(r => r.join(','))].join('\n');
    const blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8;' });
    const url = URL.createObjectURL(blob);
    const link = document.createElement('a');
    link.href = url;
    link.setAttribute('download', `soil_health_data_export.csv`);
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
  };

  return (
    <div className="bg-white border border-slate-200 rounded-3xl p-4 shadow-sm space-y-4">
      
      {/* Table controls top banner */}
      <div className="flex justify-between items-center flex-wrap gap-4 border-b border-slate-100 pb-3 select-none">
        <div>
          <h3 className="text-sm font-bold text-slate-800 flex items-center gap-1.5 leading-none">
            <Search className="w-4 h-4 text-slate-400" />
            Attributtabelle / Rohdaten aus dem Filter ({totalRows.toLocaleString()})
          </h3>
          <p className="text-[10px] text-slate-400 mt-1">
            Nutze die Spaltentitel zum Sortieren oder exportiere das Dataset als wissenschaftliche Roh-CSV.
          </p>
        </div>

        {/* Action Panel */}
        <div className="flex items-center gap-3">
          {/* Query search index input */}
          <div className="relative">
            <Search className="absolute left-3 top-2.5 w-3.5 h-3.5 text-slate-400" />
            <input
              type="text"
              placeholder="Suchen nach Standort-Details..."
              value={searchTerm}
              onChange={(e) => handleSearchChange(e.target.value)}
              className="pl-9 pr-4 py-2 bg-slate-50 border border-slate-200 hover:border-slate-300 focus:border-indigo-500/80 rounded-xl text-[11px] focus:outline-none w-[220px] transition-all font-sans placeholder-slate-400 text-slate-800"
            />
            {searchTerm && (
              <button 
                onClick={() => handleSearchChange('')}
                className="absolute right-2.5 top-2.5 text-slate-400 hover:text-slate-600 text-xs font-bold leading-none cursor-pointer"
              >
                ×
              </button>
            )}
          </div>

          {/* Export CSV dataset trigger */}
          <button
            onClick={handleExportCSV}
            className="flex items-center gap-1.5 bg-indigo-50 hover:bg-indigo-100 border border-indigo-100 text-indigo-700 px-3 py-2 rounded-xl text-[11px] font-bold cursor-pointer transition-colors shadow-sm"
          >
            <Download className="w-3.5 h-3.5" />
            CSV Exportieren
          </button>
        </div>
      </div>

      {/* RENDER TABLE CONTAINER */}
      <div className="overflow-x-auto rounded-xl border border-slate-200">
        <table className="min-w-full divide-y divide-slate-150 text-[11px]">
          <thead className="bg-[#f8fafc]">
            <tr className="select-none text-slate-500 text-[10px] uppercase font-bold">
              <th 
                className="p-3 text-left tracking-wider cursor-pointer hover:bg-slate-100 transition-colors w-24"
                onClick={() => handleSort('POINT_ID')}
              >
                <div className="flex items-center gap-1">
                  ID
                  <ArrowUpDown className="w-3 h-3 text-slate-450" />
                </div>
              </th>
              <th 
                className="p-3 cursor-pointer hover:bg-slate-100 transition-colors text-center w-24"
                onClick={() => handleSort('SHI')}
              >
                <div className="flex items-center justify-center gap-1 text-emerald-800">
                  SHI
                  <ArrowUpDown className="w-3 h-3 text-slate-450" />
                </div>
              </th>
              <th className="p-3 text-center text-indigo-805 w-24">Pred_SHI</th>
              <th 
                className="p-3 cursor-pointer hover:bg-slate-100 transition-colors text-right w-24"
                onClick={() => handleSort('height_m')}
              >
                <div className="flex items-center justify-end gap-1">
                  Höhe (m)
                  <ArrowUpDown className="w-3 h-3 text-slate-450" />
                </div>
              </th>
              <th 
                className="p-3 cursor-pointer hover:bg-slate-100 transition-colors text-right w-24"
                onClick={() => handleSort('temp_c_mean_1995_2024')}
              >
                <div className="flex items-center justify-end gap-1">
                  Temp (°C)
                  <ArrowUpDown className="w-3 h-3 text-slate-450" />
                </div>
              </th>
              <th 
                className="p-3 cursor-pointer hover:bg-slate-100 transition-colors text-right w-24"
                onClick={() => handleSort('rain_mmsqm_mean_1995_2024')}
              >
                <div className="flex items-center justify-end gap-1">
                  Regen (mm)
                  <ArrowUpDown className="w-3 h-3 text-slate-450" />
                </div>
              </th>
              <th 
                className="p-3 cursor-pointer hover:bg-slate-100 transition-colors text-left"
                onClick={() => handleSort('land_cover')}
              >
                <div className="flex items-center gap-1">
                  Cover
                  <ArrowUpDown className="w-3 h-3 text-slate-450" />
                </div>
              </th>
              <th 
                className="p-3 cursor-pointer hover:bg-slate-100 transition-colors text-left"
                onClick={() => handleSort('land_use')}
              >
                <div className="flex items-center gap-1">
                  Nutzung
                  <ArrowUpDown className="w-3 h-3 text-slate-450" />
                </div>
              </th>
              <th className="p-3 text-left">Klima-Kategorie</th>
            </tr>
          </thead>
          <tbody className="bg-white divide-y divide-slate-100">
            {paginatedData.length > 0 ? (
              paginatedData.map((p) => {
                const isSelected = p.POINT_ID === selectedPointId;
                return (
                  <tr
                    key={p.POINT_ID}
                    onClick={() => onSelectPoint(p.POINT_ID === selectedPointId ? null : p.POINT_ID)}
                    className={`cursor-pointer hover:bg-slate-50/50 transition-colors ${
                      isSelected ? 'bg-indigo-100/60 font-semibold text-indigo-900 border-l-4 border-indigo-600' : ''
                    }`}
                  >
                    <td className="p-2.5 px-3 font-mono text-slate-500">{p.POINT_ID}</td>
                    <td className="p-2.5 text-center font-bold text-teal-800 font-mono bg-slate-50/40">
                      {p.SHI.toFixed(2)}
                    </td>
                    <td className="p-2.5 text-center font-bold text-indigo-750 font-mono bg-slate-50/15">
                      {p.pred_shi?.toFixed(2) || 'N/A'}
                    </td>
                    <td className="p-2.5 text-right font-mono text-indigo-600 font-bold bg-indigo-50/5">
                      ⛰️ {p.height_m.toFixed(1)} m
                    </td>
                    <td className="p-2.5 text-right font-mono text-cyan-700 font-bold bg-cyan-50/5">
                      🌡️ {p.temp_c_mean_1995_2024.toFixed(1)} °C
                    </td>
                    <td className="p-2.5 text-right font-mono text-emerald-700 font-bold bg-emerald-50/5">
                      🌧️ {p.rain_mmsqm_mean_1995_2024.toFixed(0)} mm
                    </td>
                    <td className="p-2.5 text-left leading-none">
                      <span 
                        className="px-2 py-0.5 rounded text-[9.5px] font-bold inline-block"
                        style={{
                          backgroundColor: `${CATEGORY_COLORS[p.land_cover] || '#e2e8f0'}15`,
                          color: CATEGORY_COLORS[p.land_cover] || '#1e293b'
                        }}
                      >
                        {p.land_cover}
                      </span>
                    </td>
                    <td className="p-2.5 text-left leading-none truncate max-w-[200px]" title={p.land_use}>
                      <span 
                        className="px-2 py-0.5 rounded text-[9px] font-bold inline-block truncate max-w-full"
                        style={{
                          backgroundColor: `${CATEGORY_COLORS[p.land_use] || '#e2e8f0'}15`,
                          color: CATEGORY_COLORS[p.land_use] || '#1e293b'
                        }}
                      >
                        {p.land_use}
                      </span>
                    </td>
                    <td className="p-2.5 text-left leading-none truncate max-w-[150px]" title={p.climate_name}>
                      <span 
                        className="px-2 py-0.5 rounded text-[8.5px] font-semibold inline-block truncate max-w-full"
                        style={{
                          backgroundColor: `${CATEGORY_COLORS[p.climate_name] || '#e2e8f0'}15`,
                          color: CATEGORY_COLORS[p.climate_name] || '#475569'
                        }}
                      >
                        {p.climate_name}
                      </span>
                    </td>
                  </tr>
                );
              })
            ) : (
              <tr>
                <td colSpan={9} className="p-8 text-center text-slate-400">
                  <div className="flex flex-col items-center justify-center gap-1.5 select-none">
                    <FilterX className="w-6 h-6 text-slate-300" />
                    <span>Keine Datensätze entsprechen dem aktuellen Such- oder Baum-Filter.</span>
                  </div>
                </td>
              </tr>
            )}
          </tbody>
        </table>
      </div>

      {/* PAGINATION PANEL CONTROLS */}
      {totalRows > 0 && (
        <div className="flex justify-between items-center text-slate-500 font-sans text-[11px] flex-wrap gap-2 select-none border-t border-slate-100 pt-3">
          <div className="flex items-center gap-4">
            <span>
              Zeige <strong className="text-slate-700">{Math.min(totalRows, (currentPage - 1) * pageSize + 1)}</strong> bis{' '}
              <strong className="text-slate-700">{Math.min(totalRows, currentPage * pageSize)}</strong> von{' '}
              <strong className="text-slate-700">{totalRows}</strong> Datensätzen
            </span>
            
            <div className="flex items-center gap-1.5">
              <span>Einträge pro Seite:</span>
              <select
                value={pageSize}
                onChange={(e) => handlePageSizeChange(Number(e.target.value))}
                className="bg-slate-50 border border-slate-200 rounded p-1 cursor-pointer font-bold focus:outline-none focus:border-indigo-500"
              >
                {[5, 10, 20, 50, 100].map((sz) => (
                  <option key={sz} value={sz}>
                    {sz}
                  </option>
                ))}
              </select>
            </div>
          </div>

          <div className="flex items-center gap-2">
            <button
              onClick={() => setCurrentPage(p => Math.max(1, p - 1))}
              disabled={currentPage === 1}
              className={`p-2 py-1.5 rounded-xl border border-slate-200 cursor-pointer flex items-center justify-center transition-all ${
                currentPage === 1 ? 'opacity-40 cursor-not-allowed bg-slate-50' : 'bg-slate-50 hover:bg-slate-100 hover:border-slate-300'
              }`}
            >
              <ChevronLeft className="w-3.5 h-3.5" />
            </button>
            <span className="font-semibold text-slate-700">
              Seite {currentPage} von {totalPages}
            </span>
            <button
              onClick={() => setCurrentPage(p => Math.min(totalPages, p + 1))}
              disabled={currentPage === totalPages}
              className={`p-2 py-1.5 rounded-xl border border-slate-200 cursor-pointer flex items-center justify-center transition-all ${
                currentPage === totalPages ? 'opacity-40 cursor-not-allowed bg-slate-50' : 'bg-slate-50 hover:bg-slate-100 hover:border-slate-350'
              }`}
            >
              <ChevronRight className="w-3.5 h-3.5" />
            </button>
          </div>
        </div>
      )}

    </div>
  );
}
