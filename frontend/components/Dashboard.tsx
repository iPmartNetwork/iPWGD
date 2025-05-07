
'use client';
import { useState, useEffect } from 'react';

export default function Dashboard() {
  const [stats, setStats] = useState({ cpu: 0, ram: 0, peers: 0 });

  useEffect(() => {
    const fetchStats = async () => {
      const res = await fetch('/api/system-stats');
      const data = await res.json();
      setStats({
        cpu: data.cpu?.[0]?.value || 0,
        ram: data.ram?.[0]?.value || 0,
        peers: data.network?.length || 0
      });
    };
    fetchStats();
    const interval = setInterval(fetchStats, 5000);
    return () => clearInterval(interval);
  }, []);

  return (
    <div style={{ padding: '2rem', fontFamily: 'sans-serif' }}>
      <h1>iPWGD Admin Dashboard</h1>
      <ul style={{ marginTop: '2rem' }}>
        <li><strong>CPU Usage:</strong> {stats.cpu.toFixed(1)}%</li>
        <li><strong>RAM Usage:</strong> {stats.ram.toFixed(1)}%</li>
        <li><strong>Active Peers:</strong> {stats.peers}</li>
      </ul>
    </div>
  );
}
