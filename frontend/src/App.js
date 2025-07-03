import React, { useState, useEffect } from 'react';
import axios from 'axios';
import 'bootstrap/dist/js/bootstrap.bundle.min';
import './css/bootstrap-custom.css';
import './css/variables.css';

function App() {
  const [backendStatus, setBackendStatus] = useState('connecting');
  const [healthData, setHealthData] = useState(null);
  const [error, setError] = useState(null);

  // Test backend connection on component mount
  useEffect(() => {
    const testConnection = async () => {
      try {
        const response = await axios.get('/api/health');
        if (response.data.success) {
          setBackendStatus('connected');
          setHealthData(response.data);
          setError(null);
        } else {
          setBackendStatus('error');
          setError('Backend responded with error');
        }
      } catch (err) {
        setBackendStatus('error');
        setError(`Connection failed: ${err.message}`);
      }
    };

    testConnection();
  }, []);

  const testBackend = async () => {
    try {
      setBackendStatus('testing');
      const response = await axios.get('/api/test');
      if (response.data.success) {
        setBackendStatus('connected');
        setHealthData(response.data);
        setError(null);
      }
    } catch (err) {
      setBackendStatus('error');
      setError(`Test failed: ${err.message}`);
    }
  };

  return (
    <div className="min-vh-100 bg-light">
      {/* Navigation */}
      <nav className="navbar navbar-expand-lg navbar-dark navbar-tectonic">
        <div className="container">
          <span className="navbar-brand mb-0 h1">
            🌍 Tectonic Generator
          </span>
          <span className="navbar-text">
            Procedural Tectonic Plate Generation System
          </span>
        </div>
      </nav>

      {/* Main Content */}
      <div className="container mt-4">
        <div className="row">
          <div className="col-12">
            {/* System Status Card */}
            <div className="card card-tectonic mb-4">
              <div className="card-header">
                <h5 className="card-title mb-0">System Status</h5>
              </div>
              <div className="card-body">
                <div className="d-flex align-items-center mb-3">
                  <span className={`badge status-badge ${backendStatus === 'connected' ? 'bg-success' : backendStatus === 'error' ? 'bg-danger' : 'bg-warning'}`}>
                    <span className={`status-dot ${backendStatus}`}></span>
                    Backend: {backendStatus}
                  </span>
                </div>

                {error && (
                  <div className="alert alert-danger" role="alert">
                    <strong>Error:</strong> {error}
                  </div>
                )}

                {healthData && (
                  <div className="mb-3">
                    <h6>Backend Information</h6>
                    <pre className="bg-light p-3 rounded border">{JSON.stringify(healthData, null, 2)}</pre>
                  </div>
                )}

                <button 
                  onClick={testBackend} 
                  className="btn btn-tectonic"
                  disabled={backendStatus === 'testing'}
                >
                  {backendStatus === 'testing' ? (
                    <>
                      <span className="spinner-border spinner-border-sm me-2" role="status"></span>
                      Testing...
                    </>
                  ) : (
                    'Test Backend Connection'
                  )}
                </button>
              </div>
            </div>

            {/* Features Coming Soon Card */}
            <div className="card card-tectonic">
              <div className="card-header">
                <h5 className="card-title mb-0">Features Coming Soon</h5>
              </div>
              <div className="card-body">
                <div className="row">
                  <div className="col-md-6">
                    <div className="list-group list-group-flush">
                      <div className="list-group-item border-0">
                        <span className="me-2">⏳</span>
                        <strong>Noise Generation</strong>
                        <small className="text-muted d-block">Perlin, Simplex, Worley algorithms</small>
                      </div>
                      <div className="list-group-item border-0">
                        <span className="me-2">⏳</span>
                        <strong>Plate Detection & Analysis</strong>
                        <small className="text-muted d-block">Watershed and Voronoi methods</small>
                      </div>
                      <div className="list-group-item border-0">
                        <span className="me-2">⏳</span>
                        <strong>Interactive Parameter Controls</strong>
                        <small className="text-muted d-block">Real-time parameter adjustment</small>
                      </div>
                    </div>
                  </div>
                  <div className="col-md-6">
                    <div className="list-group list-group-flush">
                      <div className="list-group-item border-0">
                        <span className="me-2">⏳</span>
                        <strong>Real-time Visualization</strong>
                        <small className="text-muted d-block">Canvas-based rendering</small>
                      </div>
                      <div className="list-group-item border-0">
                        <span className="me-2">⏳</span>
                        <strong>WorldPainter Export</strong>
                        <small className="text-muted d-block">Direct integration support</small>
                      </div>
                      <div className="list-group-item border-0">
                        <span className="me-2">⏳</span>
                        <strong>Multiple Export Formats</strong>
                        <small className="text-muted d-block">PNG, JPG, TIFF, JSON</small>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}

export default App;