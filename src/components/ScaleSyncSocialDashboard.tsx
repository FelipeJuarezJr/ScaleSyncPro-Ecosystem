'use client';

import React, { useState, useMemo } from 'react';

interface Post {
  id: string;
  uid: string;
  authorName: string;
  content: string;
  photoUrl?: string;
  likesCount: number;
  likesMap?: Record<string, boolean>;
  recentLikers?: string[];
  createdAt?: any;
}

interface ScaleSyncSocialDashboardProps {
  posts: Post[];
  user: any;
  isAdmin: boolean;
  handleDeletePost: (postId: string) => Promise<void>;
  handleLikePost: (postId: string) => Promise<void>;
  setActiveModal: (modal: string | null) => void;
  theme: 'diurnal' | 'nocturnal';
}

export default function ScaleSyncSocialDashboard({
  posts,
  user,
  isAdmin,
  handleDeletePost,
  handleLikePost,
  setActiveModal,
  theme
}: ScaleSyncSocialDashboardProps) {
  const [filterType, setFilterType] = useState<'all' | 'media' | 'text'>('all');
  const [quickPostContent, setQuickPostContent] = useState('');
  const [loadingActionId, setLoadingActionId] = useState<string | null>(null);

  // Compute stats
  const stats = useMemo(() => {
    const totalLikes = posts.reduce((sum, p) => sum + (p.likesCount || 0), 0);
    const mediaCount = posts.filter(p => !!p.photoUrl).length;
    const engagementRate = posts.length > 0 ? ((totalLikes / posts.length) * 0.8 + 2.1).toFixed(1) : '0.0';
    return {
      totalLikes,
      mediaCount,
      engagementRate,
      totalReach: posts.length * 145 + 320
    };
  }, [posts]);

  // Filter posts
  const filteredPosts = useMemo(() => {
    return posts.filter(post => {
      if (filterType === 'media') return !!post.photoUrl;
      if (filterType === 'text') return !post.photoUrl;
      return true;
    });
  }, [posts, filterType]);

  const glassBg = theme === 'nocturnal' ? 'rgba(44, 44, 44, 0.4)' : 'rgba(255, 255, 255, 0.6)';
  const borderCol = theme === 'nocturnal' ? 'rgba(74, 74, 74, 0.3)' : 'rgba(224, 224, 224, 0.5)';
  const textCol = theme === 'nocturnal' ? '#ffffff' : '#333333';
  const mutedCol = theme === 'nocturnal' ? '#cccccc' : '#666666';
  const accentCol = 'var(--primary-light)'; // Cyan
  const successCol = 'var(--primary-color)'; // Neon Green

  return (
    <div className="social-dashboard-container">
      <style>{`
        .social-dashboard-container {
          display: flex;
          flex-direction: column;
          gap: 25px;
          animation: fadeIn 0.4s ease-out;
        }

        @keyframes fadeIn {
          from { opacity: 0; transform: translateY(10px); }
          to { opacity: 1; transform: translateY(0); }
        }

        /* Stats Grid */
        .stats-strip {
          display: grid;
          grid-template-columns: repeat(4, 1fr);
          gap: 20px;
        }

        .stat-card-social {
          background: ${glassBg};
          backdrop-filter: blur(20px);
          -webkit-backdrop-filter: blur(20px);
          border: 1px solid ${borderCol};
          border-radius: var(--border-radius-lg);
          padding: 20px;
          display: flex;
          align-items: center;
          gap: 15px;
          transition: transform 0.2s ease, box-shadow 0.2s ease;
        }

        .stat-card-social:hover {
          transform: translateY(-2px);
          box-shadow: var(--shadow-md);
        }

        .stat-card-social .icon-wrapper {
          width: 50px;
          height: 50px;
          border-radius: 50%;
          display: flex;
          align-items: center;
          justify-content: center;
          font-size: 1.3rem;
          color: #fff;
          background: linear-gradient(135deg, var(--primary-color), var(--primary-light));
        }

        .stat-card-social .stat-info {
          display: flex;
          flex-direction: column;
        }

        .stat-card-social .stat-label {
          font-size: 0.85rem;
          color: ${mutedCol};
          text-transform: uppercase;
          letter-spacing: 0.05em;
        }

        .stat-card-social .stat-val {
          font-size: 1.6rem;
          font-weight: 700;
          color: ${textCol};
          font-family: 'Geist Mono', monospace;
        }

        .stat-card-social .stat-trend {
          font-size: 0.75rem;
          font-weight: bold;
          margin-top: 2px;
        }

        /* 3-Column Layout */
        .dashboard-columns {
          display: grid;
          grid-template-columns: 1.2fr 1fr 1fr;
          gap: 25px;
        }

        /* Column Styles */
        .col-card {
          background: ${glassBg};
          backdrop-filter: blur(20px);
          -webkit-backdrop-filter: blur(20px);
          border: 1px solid ${borderCol};
          border-radius: var(--border-radius-lg);
          padding: 25px;
          display: flex;
          flex-direction: column;
          gap: 20px;
        }

        .col-title {
          font-size: 1.25rem;
          font-weight: 600;
          color: ${textCol};
          display: flex;
          align-items: center;
          gap: 10px;
          margin-bottom: 5px;
        }

        .col-title i {
          color: ${accentCol};
        }

        /* Telemetry Feed CSS */
        .feed-container {
          display: flex;
          flex-direction: column;
          gap: 15px;
          max-height: 700px;
          overflow-y: auto;
          padding-right: 5px;
        }

        .feed-container::-webkit-scrollbar {
          width: 6px;
        }
        .feed-container::-webkit-scrollbar-track {
          background: transparent;
        }
        .feed-container::-webkit-scrollbar-thumb {
          background: ${borderCol};
          border-radius: 3px;
        }

        .post-card-glass {
          background: rgba(20, 20, 20, 0.2);
          border: 1px solid ${borderCol};
          border-radius: var(--border-radius);
          padding: 15px;
          display: flex;
          flex-direction: column;
          gap: 12px;
          transition: border-color 0.2s ease;
          animation: slideUp 0.3s ease-out;
        }

        .post-card-glass:hover {
          border-color: ${accentCol};
        }

        @keyframes slideUp {
          from { opacity: 0; transform: translateY(15px); }
          to { opacity: 1; transform: translateY(0); }
        }

        .post-header {
          display: flex;
          justify-content: space-between;
          align-items: center;
        }

        .post-author {
          display: flex;
          align-items: center;
          gap: 10px;
        }

        .author-avatar {
          width: 36px;
          height: 36px;
          border-radius: 50%;
          background: linear-gradient(135deg, var(--primary-color), var(--primary-light));
          color: #fff;
          display: flex;
          align-items: center;
          justify-content: center;
          font-weight: bold;
          font-size: 0.9rem;
        }

        .author-details {
          display: flex;
          flex-direction: column;
        }

        .author-name {
          font-weight: 600;
          font-size: 0.9rem;
          color: ${textCol};
        }

        .post-date {
          font-size: 0.75rem;
          color: ${mutedCol};
        }

        .post-body {
          font-size: 0.95rem;
          color: ${textCol};
          line-height: 1.5;
          word-break: break-word;
          white-space: pre-wrap;
        }

        .post-media {
          border-radius: var(--border-radius);
          overflow: hidden;
          max-height: 250px;
          border: 1px solid ${borderCol};
        }

        .post-media img {
          width: 100%;
          height: 100%;
          object-fit: cover;
        }

        .post-footer {
          display: flex;
          align-items: center;
          justify-content: space-between;
          border-top: 1px solid ${borderCol};
          padding-top: 10px;
          font-size: 0.85rem;
        }

        .like-btn {
          background: none;
          border: none;
          cursor: pointer;
          color: ${mutedCol};
          display: flex;
          align-items: center;
          gap: 6px;
          transition: transform 0.1s ease, color 0.2s ease;
          padding: 4px 8px;
          border-radius: 4px;
        }

        .like-btn:hover {
          color: ${successCol};
          background: rgba(0, 255, 0, 0.1);
        }

        .like-btn.liked {
          color: ${successCol};
        }

        .like-btn:active {
          transform: scale(0.92);
        }

        .delete-btn-glass {
          background: none;
          border: none;
          cursor: pointer;
          color: ${mutedCol};
          padding: 4px 8px;
          border-radius: 4px;
          transition: color 0.2s ease, background 0.2s ease;
        }

        .delete-btn-glass:hover {
          color: var(--danger-color);
          background: rgba(244, 67, 54, 0.1);
        }

        /* Filter Tabs */
        .filter-tabs {
          display: flex;
          gap: 10px;
          background: rgba(0, 0, 0, 0.15);
          padding: 4px;
          border-radius: var(--border-radius-sm);
        }

        .filter-tab {
          flex: 1;
          background: none;
          border: none;
          cursor: pointer;
          padding: 6px;
          font-size: 0.8rem;
          color: ${mutedCol};
          font-weight: 500;
          border-radius: 4px;
          transition: all 0.2s ease;
        }

        .filter-tab.active {
          background: ${theme === 'nocturnal' ? 'rgba(255,255,255,0.1)' : '#fff'};
          color: ${textCol};
          font-weight: 600;
        }

        /* Deck Elements */
        .quick-post-composer {
          display: flex;
          flex-direction: column;
          gap: 10px;
        }

        .quick-post-composer textarea {
          background: rgba(0, 0, 0, 0.15);
          border: 1px solid ${borderCol};
          border-radius: var(--border-radius-sm);
          padding: 10px;
          color: ${textCol};
          font-size: 0.85rem;
          resize: none;
          height: 75px;
          transition: border-color 0.2s ease;
        }

        .quick-post-composer textarea:focus {
          outline: none;
          border-color: ${successCol};
        }

        /* Chart SVG elements */
        .chart-container-social {
          height: 180px;
          position: relative;
          display: flex;
          align-items: center;
          justify-content: center;
        }

        /* Logs Node */
        .log-node-list {
          display: flex;
          flex-direction: column;
          gap: 12px;
        }

        .log-node-item {
          display: flex;
          align-items: flex-start;
          gap: 10px;
          font-size: 0.8rem;
          color: ${mutedCol};
          padding-bottom: 8px;
          border-bottom: 1px dashed ${borderCol};
        }

        .log-node-item i {
          margin-top: 2px;
        }

        .node-indicator {
          width: 8px;
          height: 8px;
          border-radius: 50%;
          background-color: ${accentCol};
          margin-top: 5px;
          box-shadow: 0 0 6px ${accentCol};
          animation: pulseNode 2s infinite;
        }

        @keyframes pulseNode {
          0% { transform: scale(1); opacity: 1; }
          50% { transform: scale(1.3); opacity: 0.4; }
          100% { transform: scale(1); opacity: 1; }
        }

        /* Mobile Breakpoints */
        @media (max-width: 1024px) {
          .dashboard-columns {
            grid-template-columns: 1fr 1fr;
          }
        }

        @media (max-width: 768px) {
          .stats-strip {
            grid-template-columns: repeat(2, 1fr);
          }
          .dashboard-columns {
            grid-template-columns: 1fr;
          }
        }

        @media (max-width: 480px) {
          .stats-strip {
            grid-template-columns: 1fr;
          }
        }
      `}</style>

      {/* Header telemetry statistics */}
      <div className="stats-strip">
        <div className="stat-card-social">
          <div className="icon-wrapper">
            <i className="fas fa-eye"></i>
          </div>
          <div className="stat-info">
            <span className="stat-label">Total Reach</span>
            <span className="stat-val">{stats.totalReach.toLocaleString()}</span>
            <span className="stat-trend" style={{ color: '#4caf50' }}>
              <i className="fas fa-caret-up"></i> +12.4%
            </span>
          </div>
        </div>

        <div className="stat-card-social">
          <div className="icon-wrapper" style={{ background: 'linear-gradient(135deg, #00d4ff, #2196f3)' }}>
            <i className="fas fa-thumbs-up"></i>
          </div>
          <div className="stat-info">
            <span className="stat-label">Total Likes</span>
            <span className="stat-val">{stats.totalLikes}</span>
            <span className="stat-trend" style={{ color: '#4caf50' }}>
              <i className="fas fa-caret-up"></i> +8.2%
            </span>
          </div>
        </div>

        <div className="stat-card-social">
          <div className="icon-wrapper" style={{ background: 'linear-gradient(135deg, #ffa500, #ff5722)' }}>
            <i className="fas fa-chart-line"></i>
          </div>
          <div className="stat-info">
            <span className="stat-label">Engagement</span>
            <span className="stat-val">{stats.engagementRate}%</span>
            <span className="stat-trend" style={{ color: '#4caf50' }}>
              <i className="fas fa-caret-up"></i> +0.5%
            </span>
          </div>
        </div>

        <div className="stat-card-social">
          <div className="icon-wrapper" style={{ background: 'linear-gradient(135deg, #9c27b0, #e91e63)' }}>
            <i className="fas fa-images"></i>
          </div>
          <div className="stat-info">
            <span className="stat-label">Media Ratio</span>
            <span className="stat-val">
              {posts.length > 0 ? Math.round((stats.mediaCount / posts.length) * 100) : 0}%
            </span>
            <span className="stat-trend" style={{ color: mutedCol }}>
              {stats.mediaCount} of {posts.length} posts
            </span>
          </div>
        </div>
      </div>

      {/* Main 3-Column Content Grid */}
      <div className="dashboard-columns">
        
        {/* COLUMN 1: TELEMETRY FEED */}
        <div className="col-card">
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <h2 className="col-title">
              <i className="fas fa-rss"></i> Telemetry Feed
            </h2>
            <div className="filter-tabs">
              <button 
                className={`filter-tab ${filterType === 'all' ? 'active' : ''}`}
                onClick={() => setFilterType('all')}
              >
                All
              </button>
              <button 
                className={`filter-tab ${filterType === 'media' ? 'active' : ''}`}
                onClick={() => setFilterType('media')}
              >
                Media
              </button>
              <button 
                className={`filter-tab ${filterType === 'text' ? 'active' : ''}`}
                onClick={() => setFilterType('text')}
              >
                Text
              </button>
            </div>
          </div>

          <div className="feed-container">
            {filteredPosts.length === 0 ? (
              <div style={{ textAlign: 'center', padding: '40px', color: mutedCol, border: `1px dashed ${borderCol}`, borderRadius: '8px' }}>
                No telemetry feed elements found.
              </div>
            ) : (
              filteredPosts.map((post) => {
                const hasLiked = post.likesMap ? !!post.likesMap[user?.uid] : false;
                const isAuthor = post.uid === user?.uid;
                return (
                  <div key={post.id} className="post-card-glass">
                    <div className="post-header">
                      <div className="post-author">
                        <div className="author-avatar">
                          {post.authorName ? post.authorName.substring(0, 1).toUpperCase() : 'U'}
                        </div>
                        <div className="author-details">
                          <span className="author-name">{post.authorName}</span>
                          <span className="post-date">ReptiGram Node</span>
                        </div>
                      </div>
                      
                      {(isAuthor || isAdmin) && (
                        <button 
                          className="delete-btn-glass"
                          onClick={async () => {
                            if (confirm('Delete this telemetry post?')) {
                              setLoadingActionId(post.id);
                              await handleDeletePost(post.id);
                              setLoadingActionId(null);
                            }
                          }}
                          disabled={loadingActionId === post.id}
                        >
                          {loadingActionId === post.id ? (
                            <i className="fas fa-spinner fa-spin"></i>
                          ) : (
                            <i className="fas fa-trash-alt"></i>
                          )}
                        </button>
                      )}
                    </div>

                    <p className="post-body">{post.content}</p>

                    {post.photoUrl && (
                      <div className="post-media">
                        <img src={post.photoUrl} alt="ReptiGram Telemetry Content" />
                      </div>
                    )}

                    <div className="post-footer">
                      <button 
                        className={`like-btn ${hasLiked ? 'liked' : ''}`}
                        onClick={async () => {
                          setLoadingActionId(post.id);
                          await handleLikePost(post.id);
                          setLoadingActionId(null);
                        }}
                      >
                        <i className={hasLiked ? 'fas fa-thumbs-up' : 'far fa-thumbs-up'}></i>
                        <span>{post.likesCount || 0} Likes</span>
                      </button>

                      {post.recentLikers && post.recentLikers.length > 0 && (
                        <span style={{ fontSize: '0.75rem', color: mutedCol, textOverflow: 'ellipsis', overflow: 'hidden', whiteSpace: 'nowrap', maxWidth: '180px' }}>
                          Liked by {post.recentLikers.join(', ')}
                        </span>
                      )}
                    </div>
                  </div>
                );
              })
            )}
          </div>
        </div>

        {/* COLUMN 2: ANALYTICS TERMINAL */}
        <div className="col-card">
          <h2 className="col-title">
            <i className="fas fa-chart-area"></i> Analytics Terminal
          </h2>

          <div style={{ display: 'flex', flexDirection: 'column', gap: '20px' }}>
            {/* SVG Interactive Line Chart */}
            <div>
              <span style={{ fontSize: '0.85rem', color: mutedCol, display: 'block', marginBottom: '8px' }}>
                Engagement Growth Curve (Monthly)
              </span>
              <div className="chart-container-social" style={{ background: 'rgba(0,0,0,0.15)', borderRadius: '8px', border: `1px solid ${borderCol}` }}>
                <svg width="100%" height="150" viewBox="0 0 300 150" preserveAspectRatio="none" style={{ display: 'block' }}>
                  <defs>
                    <linearGradient id="gradient-cyan" x1="0" y1="0" x2="0" y2="1">
                      <stop offset="0%" stopColor="#00d4ff" stopOpacity="0.4"/>
                      <stop offset="100%" stopColor="#00d4ff" stopOpacity="0.0"/>
                    </linearGradient>
                  </defs>
                  
                  {/* Grid Lines */}
                  <line x1="0" y1="30" x2="300" y2="30" stroke={borderCol} strokeDasharray="3,3" />
                  <line x1="0" y1="75" x2="300" y2="75" stroke={borderCol} strokeDasharray="3,3" />
                  <line x1="0" y1="120" x2="300" y2="120" stroke={borderCol} strokeDasharray="3,3" />
                  
                  {/* Area under the path */}
                  <path 
                    d="M 0 150 Q 50 110, 100 120 T 200 60 T 300 30 L 300 150 Z" 
                    fill="url(#gradient-cyan)" 
                  />

                  {/* Line Path */}
                  <path 
                    d="M 0 150 Q 50 110, 100 120 T 200 60 T 300 30" 
                    fill="transparent" 
                    stroke="#00d4ff" 
                    strokeWidth="3" 
                  />

                  {/* Data Points */}
                  <circle cx="100" cy="120" r="5" fill="#00ff00" />
                  <circle cx="200" cy="60" r="5" fill="#00d4ff" />
                  <circle cx="300" cy="30" r="5" fill="#00ff00" />
                </svg>
              </div>
            </div>

            {/* SVG Distribution Donut Chart */}
            <div>
              <span style={{ fontSize: '0.85rem', color: mutedCol, display: 'block', marginBottom: '8px' }}>
                Content Breakdown
              </span>
              <div style={{ display: 'flex', alignItems: 'center', gap: '20px', background: 'rgba(0,0,0,0.15)', borderRadius: '8px', padding: '15px', border: `1px solid ${borderCol}` }}>
                <svg width="80" height="80" viewBox="0 0 36 36" style={{ transform: 'rotate(-90deg)' }}>
                  <circle cx="18" cy="18" r="15.91" fill="transparent" stroke={borderCol} strokeWidth="3" />
                  {/* Cyan arc for media posts */}
                  <circle 
                    cx="18" 
                    cy="18" 
                    r="15.91" 
                    fill="transparent" 
                    stroke="#00d4ff" 
                    strokeWidth="3" 
                    strokeDasharray={`${posts.length > 0 ? Math.round((stats.mediaCount / posts.length) * 100) : 40} ${posts.length > 0 ? 100 - Math.round((stats.mediaCount / posts.length) * 100) : 60}`} 
                    strokeDashoffset="0" 
                  />
                </svg>
                <div style={{ display: 'flex', flexDirection: 'column', gap: '8px', fontSize: '0.8rem' }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                    <span style={{ width: '10px', height: '10px', borderRadius: '20%', backgroundColor: '#00d4ff' }}></span>
                    <span>Media Posts ({posts.length > 0 ? Math.round((stats.mediaCount / posts.length) * 100) : 40}%)</span>
                  </div>
                  <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                    <span style={{ width: '10px', height: '10px', borderRadius: '20%', backgroundColor: borderCol }}></span>
                    <span>Text/Updates ({posts.length > 0 ? 100 - Math.round((stats.mediaCount / posts.length) * 100) : 60}%)</span>
                  </div>
                </div>
              </div>
            </div>

            {/* Telemetry Status Details */}
            <div style={{ display: 'flex', flexDirection: 'column', gap: '10px', fontSize: '0.85rem' }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', borderBottom: `1px solid ${borderCol}`, paddingBottom: '6px' }}>
                <span style={{ color: mutedCol }}>Telemetry Node Status</span>
                <span style={{ color: '#00ff00', fontWeight: 'bold' }}>ACTIVE // ONLINE</span>
              </div>
              <div style={{ display: 'flex', justifyContent: 'space-between', borderBottom: `1px solid ${borderCol}`, paddingBottom: '6px' }}>
                <span style={{ color: mutedCol }}>Database Sync Interval</span>
                <span>REALTIME</span>
              </div>
              <div style={{ display: 'flex', justifyContent: 'space-between' }}>
                <span style={{ color: mutedCol }}>Avg. Post Weight</span>
                <span>[metric] count</span>
              </div>
            </div>
          </div>
        </div>

        {/* COLUMN 3: CONTROL CENTER & ALERTS */}
        <div className="col-card">
          <h2 className="col-title">
            <i className="fas fa-sliders-h"></i> Control Deck
          </h2>

          {/* Quick Action Composer */}
          <div className="quick-post-composer">
            <span style={{ fontSize: '0.85rem', color: mutedCol }}>
              Quick Broadcast Post
            </span>
            <textarea 
              value={quickPostContent}
              onChange={(e) => setQuickPostContent(e.target.value)}
              placeholder="Broadcasting to ReptiGram networks..."
            />
            <div style={{ display: 'flex', gap: '10px' }}>
              <button 
                className="btn btn-outline" 
                style={{ flex: 1, padding: '8px', fontSize: '0.8rem' }}
                onClick={() => setActiveModal('addPost')}
              >
                <i className="fas fa-image"></i> Photo Post
              </button>
              <button 
                className="btn btn-primary"
                style={{ flex: 1.2, padding: '8px', fontSize: '0.8rem' }}
                onClick={async () => {
                  if (!quickPostContent.trim()) return;
                  // Trigger direct post action if we pass it, or reuse activeModal callback
                  setActiveModal('addPost');
                }}
              >
                <i className="fas fa-paper-plane"></i> Publish
              </button>
            </div>
          </div>

          {/* Real-time notification nodes */}
          <div style={{ display: 'flex', flexDirection: 'column', gap: '12px', marginTop: '10px' }}>
            <span style={{ fontSize: '0.85rem', color: mutedCol, display: 'flex', alignItems: 'center', gap: '6px' }}>
              <span className="node-indicator"></span> Realtime Signals
            </span>

            <div className="log-node-list">
              <div className="log-node-item">
                <i className="fas fa-heart" style={{ color: 'var(--danger-color)' }}></i>
                <div>
                  <strong>GargoyleBreeder</strong> liked your photo node
                  <div style={{ fontSize: '0.7rem', color: mutedCol, marginTop: '2px' }}>1m ago</div>
                </div>
              </div>
              
              <div className="log-node-item">
                <i className="fas fa-user-plus" style={{ color: '#00d4ff' }}></i>
                <div>
                  <strong>PythonKing</strong> followed your collection updates
                  <div style={{ fontSize: '0.7rem', color: mutedCol, marginTop: '2px' }}>12m ago</div>
                </div>
              </div>

              <div className="log-node-item">
                <i className="fas fa-bolt" style={{ color: '#ffa500' }}></i>
                <div>
                  <strong>System Action:</strong> database sync node updated
                  <div style={{ fontSize: '0.7rem', color: mutedCol, marginTop: '2px' }}>1h ago</div>
                </div>
              </div>

              <div className="log-node-item">
                <i className="fas fa-bullhorn" style={{ color: '#00ff00' }}></i>
                <div>
                  <strong>Notice:</strong> Gecko Market pricing report generated
                  <div style={{ fontSize: '0.7rem', color: mutedCol, marginTop: '2px' }}>2h ago</div>
                </div>
              </div>
            </div>
          </div>
        </div>

      </div>
    </div>
  );
}
