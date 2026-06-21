"use client";

import React, { useState, useEffect } from "react";
import { useRouter } from "next/navigation";
import DevAdminInitializer from "./components/DevAdminInitializer";
import ScaleSyncSocialDashboard from "@/src/components/ScaleSyncSocialDashboard";
import {
  createBreedingProjectAction,
  getBreedingProjectsAction,
  deleteBreedingProjectAction,
  createPostAction,
  getPostsAction,
  likePostAction,
  deletePostAction,
  createListingAction,
  getListingsAction,
  deleteListingAction,
  updateListingStatusAction,
  createReptileAction,
  getReptilesAction,
  deleteReptileAction,
  setAdminClaimAction,
  checkCurrentAdminStatus
} from "./actions";
import { auth } from "./firebase-client";
import { signOut } from "firebase/auth";

type SectionType = "dashboard" | "animals" | "breeding" | "schedule" | "inventory" | "social" | "marketplace" | "reports";

export default function DashboardPage() {
  const router = useRouter();
  const [activeSection, setActiveSection] = useState<SectionType>("dashboard");
  const [user, setUser] = useState<any>(null);
  const [isAdmin, setIsAdmin] = useState(false);
  const [loading, setLoading] = useState(true);

  // App Theme
  const [theme, setTheme] = useState<"diurnal" | "nocturnal">("diurnal");

  // User Dropdown State
  const [userDropdownActive, setUserDropdownActive] = useState(false);
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);

  // Data states
  const [reptiles, setReptiles] = useState<any[]>([]);
  const [breedingProjects, setBreedingProjects] = useState<any[]>([]);
  const [tasks, setTasks] = useState<any[]>([]);
  const [inventory, setInventory] = useState<any[]>([]);
  const [posts, setPosts] = useState<any[]>([]);
  const [listings, setListings] = useState<any[]>([]);

  // Modals visibility
  const [activeModal, setActiveModal] = useState<string | null>(null);

  // QR Code details state
  const [qrCodeData, setQrCodeData] = useState<string | null>(null);

  // Form input states
  const [reptileForm, setReptileForm] = useState({
    name: "", species: "Ball Python", gender: "Female", morph: "",
    birthDate: "", acquisitionDate: "", breeder: "", notes: "", status: "active"
  });
  const [breedingForm, setBreedingForm] = useState({
    projectName: "", male: "", female: "", startDate: "", notes: ""
  });
  const [taskForm, setTaskForm] = useState({
    taskType: "Feeding", target: "", taskDate: "", taskTime: "", notes: ""
  });
  const [inventoryForm, setInventoryForm] = useState({
    itemName: "", quantity: 1, unit: "pcs", costPerUnit: 0, purchaseDate: "", notes: ""
  });
  const [postForm, setPostForm] = useState({ content: "", photoUrl: "" });
  const [listingForm, setListingForm] = useState({
    title: "", description: "", price: 0, species: "Ball Python", morph: "", gender: "Female", photoUrl: ""
  });
  const [targetUidClaim, setTargetUidClaim] = useState("");
  const [targetAdminVal, setTargetAdminVal] = useState(true);

  // Feedings record shortcut state
  const [selectedReptileForFeeding, setSelectedReptileForFeeding] = useState("");
  const [foodType, setFoodType] = useState("Weaned Rat");
  const [preyWeight, setPreyWeight] = useState(30);

  // Notification Banner
  const [notification, setNotification] = useState<{ text: string; type: "success" | "error" } | null>(null);

  const triggerNotification = (text: string, type: "success" | "error" = "success") => {
    setNotification({ text, type });
    setTimeout(() => setNotification(null), 4000);
  };

  // Check authentication and load local data
  useEffect(() => {
    const checkAuth = async () => {
      // Re-initialize theme from cache if exists
      const savedTheme = localStorage.getItem("theme") as "diurnal" | "nocturnal" | null;
      if (savedTheme) {
        setTheme(savedTheme);
        document.documentElement.setAttribute("data-theme", savedTheme);
      } else {
        document.documentElement.setAttribute("data-theme", "diurnal");
      }

      // Check user session
      const userData = JSON.parse(localStorage.getItem("userData") || sessionStorage.getItem("userData") || "null");
      if (!userData) {
        router.push("/login");
        return;
      }
      setUser(userData);

      // Verify admin claim
      const adminClaim = await checkCurrentAdminStatus();
      setIsAdmin(adminClaim);

      setLoading(false);
    };

    checkAuth();
  }, [router]);

  // Load and refresh core data
  const fetchData = async () => {
    if (!user) return;

    // Fetch Reptiles
    const repsRes = await getReptilesAction(user.uid);
    if (repsRes.success && repsRes.data) {
      setReptiles(repsRes.data);
    }

    // Fetch Breeding
    const breedRes = await getBreedingProjectsAction(user.uid);
    if (breedRes.success && breedRes.data) {
      setBreedingProjects(breedRes.data);
    }

    // Fetch Social
    const postsRes = await getPostsAction();
    if (postsRes.success && postsRes.data) {
      setPosts(postsRes.data);
    }

    // Fetch Marketplace
    const listRes = await getListingsAction();
    if (listRes.success && listRes.data) {
      setListings(listRes.data);
    }
  };

  useEffect(() => {
    if (user) {
      fetchData();
      
      // Load static mock items for schedules & inventories
      setTasks([
        { id: "t1", taskType: "Feeding", target: "Luna (Ball Python)", date: "Today", time: "18:00", status: "pending" },
        { id: "t2", taskType: "Clean Enclosure", target: "Rex (Leopard Gecko)", date: "Today", time: "20:00", status: "pending" },
        { id: "t3", taskType: "Health Check", target: "Sunny (Bearded Dragon)", date: "Tomorrow", time: "10:00", status: "pending" },
      ]);
      setInventory([
        { id: "i1", itemName: "Frozen Mice (Medium)", quantity: 45, unit: "pcs", cost: 1.2, alertLimit: 10 },
        { id: "i2", itemName: "Coco Coir Bedding", quantity: 3, unit: "bricks", cost: 8.5, alertLimit: 1 },
        { id: "i3", itemName: "Calcium Supplement Powder", quantity: 1, unit: "bottle", cost: 12.0, alertLimit: 0 },
      ]);
    }
  }, [user]);

  const toggleTheme = () => {
    const newTheme = theme === "diurnal" ? "nocturnal" : "diurnal";
    setTheme(newTheme);
    localStorage.setItem("theme", newTheme);
    document.documentElement.setAttribute("data-theme", newTheme);
  };

  const handleLogout = async () => {
    try {
      await signOut(auth);
      // Clean cookie and localStorage
      document.cookie = "__session=; path=/; expires=Thu, 01 Jan 1970 00:00:00 UTC; SameSite=Lax;";
      localStorage.removeItem("userData");
      sessionStorage.removeItem("userData");
      router.push("/login");
    } catch (e: any) {
      console.error(e);
      triggerNotification("Sign out failed", "error");
    }
  };

  // Mutations
  const handleAddReptile = async (e: React.FormEvent) => {
    e.preventDefault();
    const res = await createReptileAction(user.uid, reptileForm);
    if (res.success) {
      triggerNotification("Reptile successfully added!");
      setActiveModal(null);
      setReptileForm({
        name: "", species: "Ball Python", gender: "Female", morph: "",
        birthDate: "", acquisitionDate: "", breeder: "", notes: "", status: "active"
      });
      fetchData();
    } else {
      triggerNotification(res.error || "Failed to add reptile", "error");
    }
  };

  const handleDeleteReptile = async (id: string) => {
    if (!confirm("Are you sure you want to delete this reptile?")) return;
    const res = await deleteReptileAction(user.uid, id);
    if (res.success) {
      triggerNotification("Reptile deleted.");
      fetchData();
    } else {
      triggerNotification(res.error || "Failed to delete reptile", "error");
    }
  };

  const handleAddBreeding = async (e: React.FormEvent) => {
    e.preventDefault();
    const res = await createBreedingProjectAction(user.uid, breedingForm);
    if (res.success) {
      triggerNotification("Breeding pairing created!");
      setActiveModal(null);
      setBreedingForm({ projectName: "", male: "", female: "", startDate: "", notes: "" });
      fetchData();
    } else {
      triggerNotification(res.error || "Failed to create pairing", "error");
    }
  };

  const handleDeleteBreeding = async (id: string) => {
    if (!confirm("Delete this breeding pairing?")) return;
    const res = await deleteBreedingProjectAction(user.uid, id);
    if (res.success) {
      triggerNotification("Breeding pairing removed.");
      fetchData();
    } else {
      triggerNotification(res.error || "Failed to delete pairing", "error");
    }
  };

  const handleAddFeedLog = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!selectedReptileForFeeding) {
      triggerNotification("Please select a reptile", "error");
      return;
    }
    triggerNotification(`Feeding log registered successfully for selected reptile!`);
    setActiveModal(null);
  };

  const handleAddTask = (e: React.FormEvent) => {
    e.preventDefault();
    const newTask = {
      id: Math.random().toString(),
      taskType: taskForm.taskType,
      target: taskForm.target || "General",
      date: taskForm.taskDate || "Today",
      time: taskForm.taskTime || "12:00",
      status: "pending"
    };
    setTasks([newTask, ...tasks]);
    triggerNotification("Task scheduled!");
    setActiveModal(null);
    setTaskForm({ taskType: "Feeding", target: "", taskDate: "", taskTime: "", notes: "" });
  };

  const handleAddInventory = (e: React.FormEvent) => {
    e.preventDefault();
    const newItem = {
      id: Math.random().toString(),
      itemName: inventoryForm.itemName,
      quantity: Number(inventoryForm.quantity),
      unit: inventoryForm.unit,
      cost: Number(inventoryForm.costPerUnit),
      alertLimit: 5
    };
    setInventory([newItem, ...inventory]);
    triggerNotification("Supply inventory updated!");
    setActiveModal(null);
    setInventoryForm({ itemName: "", quantity: 1, unit: "pcs", costPerUnit: 0, purchaseDate: "", notes: "" });
  };

  const handleAddPost = async (e: React.FormEvent) => {
    e.preventDefault();
    const res = await createPostAction(user.uid, user.name, postForm.content, postForm.photoUrl);
    if (res.success) {
      triggerNotification("Post published to social feed!");
      setActiveModal(null);
      setPostForm({ content: "", photoUrl: "" });
      fetchData();
    } else {
      triggerNotification(res.error || "Failed to publish post", "error");
    }
  };

  const handleLikePost = async (postId: string) => {
    const res = await likePostAction(postId, user.uid);
    if (res.success) {
      fetchData();
    } else {
      triggerNotification(res.error || "Failed to register like", "error");
    }
  };

  const handleDeletePost = async (postId: string) => {
    if (!confirm("Are you sure you want to delete this post?")) return;
    const res = await deletePostAction(user.uid, postId);
    if (res.success) {
      triggerNotification("Post deleted.");
      fetchData();
    } else {
      triggerNotification(res.error || "Failed to delete post", "error");
    }
  };

  const handleAddListing = async (e: React.FormEvent) => {
    e.preventDefault();
    const res = await createListingAction(user.uid, {
      title: listingForm.title,
      description: listingForm.description,
      price: Number(listingForm.price),
      species: listingForm.species,
      morph: listingForm.morph,
      gender: listingForm.gender,
      photoUrls: listingForm.photoUrl ? [listingForm.photoUrl] : []
    });
    if (res.success) {
      triggerNotification("Listing published to internal marketplace!");
      setActiveModal(null);
      setListingForm({
        title: "", description: "", price: 0, species: "Ball Python", morph: "", gender: "Female", photoUrl: ""
      });
      fetchData();
    } else {
      triggerNotification(res.error || "Failed to create listing", "error");
    }
  };

  const handleDeleteListing = async (listingId: string) => {
    if (!confirm("Are you sure you want to delete this listing?")) return;
    const res = await deleteListingAction(user.uid, listingId);
    if (res.success) {
      triggerNotification("Listing removed.");
      fetchData();
    } else {
      triggerNotification(res.error || "Failed to delete listing", "error");
    }
  };

  const handleSetAdminClaim = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!targetUidClaim) return;
    const res = await setAdminClaimAction(targetUidClaim, targetAdminVal);
    if (res.success) {
      triggerNotification(`Role claim successfully written to UID: ${targetUidClaim}`);
      setTargetUidClaim("");
    } else {
      triggerNotification(res.error || "Failed to set claim", "error");
    }
  };

  if (loading) {
    return (
      <div style={{ display: "flex", height: "100vh", alignItems: "center", justifyContent: "center", background: "#1a1a1a", color: "#00ff00", fontFamily: "monospace" }}>
        <div style={{ textAlign: "center" }}>
          <i className="fas fa-spinner fa-spin" style={{ fontSize: "3rem", marginBottom: "20px" }}></i>
          <h2>INITIALIZING SCALESYNC BACKEND CONFIGURATION...</h2>
        </div>
      </div>
    );
  }

  return (
    <>
      <DevAdminInitializer />
      
      {/* Notification Banner */}
      {notification && (
        <div 
          style={{
            position: "fixed", top: "85px", right: "20px", zIndex: 9999,
            padding: "15px 25px", borderRadius: "8px", color: "#fff",
            backgroundColor: notification.type === "success" ? "#4caf50" : "#f44336",
            boxShadow: "0 4px 12px rgba(0,0,0,0.2)", display: "flex", alignItems: "center", gap: "10px"
          }}
        >
          <i className={notification.type === "success" ? "fas fa-check-circle" : "fas fa-exclamation-circle"}></i>
          <span>{notification.text}</span>
        </div>
      )}

      {/* Navigation */}
      <nav className="navbar">
        <div className="nav-container">
          <div className="nav-brand">
            <i className="fas fa-dragon"></i>
            <span>ScaleSyncPro</span>
          </div>
          
          <div className={`nav-menu ${mobileMenuOpen ? "active" : ""}`} style={mobileMenuOpen ? { display: "flex", flexDirection: "column", position: "absolute", top: "70px", left: 0, right: 0, backgroundColor: "var(--bg-primary)", padding: "20px", borderBottom: "1px solid var(--border-color)", gap: "15px" } : {}}>
            <button 
              className={`nav-link ${activeSection === "dashboard" ? "active" : ""}`} 
              onClick={() => { setActiveSection("dashboard"); setMobileMenuOpen(false); }}
              style={{ background: "none", border: "none", cursor: "pointer", textAlign: "left" }}
            >
              <i className="fas fa-home"></i>
              <span>Dashboard</span>
            </button>
            <button 
              className={`nav-link ${activeSection === "animals" ? "active" : ""}`} 
              onClick={() => { setActiveSection("animals"); setMobileMenuOpen(false); }}
              style={{ background: "none", border: "none", cursor: "pointer", textAlign: "left" }}
            >
              <i className="fas fa-dragon"></i>
              <span>Reptiles</span>
            </button>
            <button 
              className={`nav-link ${activeSection === "breeding" ? "active" : ""}`} 
              onClick={() => { setActiveSection("breeding"); setMobileMenuOpen(false); }}
              style={{ background: "none", border: "none", cursor: "pointer", textAlign: "left" }}
            >
              <i className="fas fa-dna"></i>
              <span>Breeding</span>
            </button>
            <button 
              className={`nav-link ${activeSection === "schedule" ? "active" : ""}`} 
              onClick={() => { setActiveSection("schedule"); setMobileMenuOpen(false); }}
              style={{ background: "none", border: "none", cursor: "pointer", textAlign: "left" }}
            >
              <i className="fas fa-calendar"></i>
              <span>Schedule</span>
            </button>
            <button 
              className={`nav-link ${activeSection === "inventory" ? "active" : ""}`} 
              onClick={() => { setActiveSection("inventory"); setMobileMenuOpen(false); }}
              style={{ background: "none", border: "none", cursor: "pointer", textAlign: "left" }}
            >
              <i className="fas fa-box"></i>
              <span>Inventory</span>
            </button>
            <button 
              className={`nav-link ${activeSection === "social" ? "active" : ""}`} 
              onClick={() => { setActiveSection("social"); setMobileMenuOpen(false); }}
              style={{ background: "none", border: "none", cursor: "pointer", textAlign: "left" }}
            >
              <i className="fas fa-users"></i>
              <span>ReptiGram Feed</span>
            </button>
            <button 
              className={`nav-link ${activeSection === "marketplace" ? "active" : ""}`} 
              onClick={() => { setActiveSection("marketplace"); setMobileMenuOpen(false); }}
              style={{ background: "none", border: "none", cursor: "pointer", textAlign: "left" }}
            >
              <i className="fas fa-store"></i>
              <span>Marketplace</span>
            </button>
            <button 
              className={`nav-link ${activeSection === "reports" ? "active" : ""}`} 
              onClick={() => { setActiveSection("reports"); setMobileMenuOpen(false); }}
              style={{ background: "none", border: "none", cursor: "pointer", textAlign: "left" }}
            >
              <i className="fas fa-chart-bar"></i>
              <span>Reports</span>
            </button>
          </div>

          <div className="nav-user">
            <div className="user-info">
              <span className="plan-badge" style={{ backgroundColor: isAdmin ? "#00ff00" : "var(--accent-color)", color: isAdmin ? "#000" : "#fff" }}>
                {isAdmin ? "Admin" : user?.plan || "Free"}
              </span>
              <span className="user-name">{user?.name || "User"}</span>
            </div>
            
            <div className="user-menu" style={{ position: "relative" }}>
              <button className="user-menu-toggle" onClick={() => setUserDropdownActive(!userDropdownActive)}>
                <i className="fas fa-user-circle"></i>
              </button>
              
              {userDropdownActive && (
                <div className="user-dropdown active" style={{ display: "block" }}>
                  <div className="user-dropdown-header">
                    <span>{user?.name}</span>
                    <span>{user?.email}</span>
                  </div>
                  <div className="user-dropdown-actions">
                    <button 
                      className="dropdown-item" 
                      onClick={() => { toggleTheme(); setUserDropdownActive(false); }}
                      style={{ background: "none", border: "none", width: "100%", cursor: "pointer", textAlign: "left" }}
                    >
                      <i className={theme === "diurnal" ? "fas fa-moon" : "fas fa-sun"}></i>
                      <span>{theme === "diurnal" ? "Switch to Dark" : "Switch to Light"}</span>
                    </button>
                    {process.env.NODE_ENV === "development" && (
                      <button 
                        className="dropdown-item" 
                        onClick={() => { setActiveModal("claimManager"); setUserDropdownActive(false); }}
                        style={{ background: "none", border: "none", width: "100%", cursor: "pointer", textAlign: "left", color: "#00ff00" }}
                      >
                        <i className="fas fa-shield-alt"></i>
                        <span>Admin Role Claims</span>
                      </button>
                    )}
                    <div className="dropdown-divider"></div>
                    <button 
                      className="dropdown-item" 
                      onClick={handleLogout}
                      style={{ background: "none", border: "none", width: "100%", cursor: "pointer", textAlign: "left" }}
                    >
                      <i className="fas fa-sign-out-alt"></i>
                      <span>Sign Out</span>
                    </button>
                  </div>
                </div>
              )}
            </div>

            <button className="menu-toggle" onClick={() => setMobileMenuOpen(!mobileMenuOpen)}>
              <i className="fas fa-bars"></i>
            </button>
          </div>
        </div>
      </nav>

      {/* Main Content Area */}
      <main className="main-content">
        
        {/* ==================================================== */}
        {/* SECTION: DASHBOARD */}
        {/* ==================================================== */}
        {activeSection === "dashboard" && (
          <section className="content-section active">
            <div className="section-header">
              <h1>Dashboard Overview</h1>
              <p>Quick health metrics and analytics for your reptile breeding facility.</p>
            </div>
            
            <div className="dashboard-grid">
              <div className="stats-grid">
                <div className="stat-card" onClick={() => setActiveSection("animals")} style={{ cursor: "pointer" }}>
                  <div className="stat-icon"><i className="fas fa-dragon"></i></div>
                  <div className="stat-content">
                    <h3>Total Reptiles</h3>
                    <p className="stat-number">{reptiles.length}</p>
                    <p className="stat-change positive">Interactive specimens roster</p>
                  </div>
                </div>

                <div className="stat-card" onClick={() => setActiveSection("breeding")} style={{ cursor: "pointer" }}>
                  <div className="stat-icon"><i className="fas fa-dna"></i></div>
                  <div className="stat-content">
                    <h3>Breeding Pairs</h3>
                    <p className="stat-number">{breedingProjects.length}</p>
                    <p className="stat-change positive">Genetics & pairings planner</p>
                  </div>
                </div>

                <div className="stat-card" onClick={() => setActiveSection("schedule")} style={{ cursor: "pointer" }}>
                  <div className="stat-icon"><i className="fas fa-calendar-check"></i></div>
                  <div className="stat-content">
                    <h3>Pending Tasks</h3>
                    <p className="stat-number">{tasks.length}</p>
                    <p className="stat-change negative">Tasks needing attention</p>
                  </div>
                </div>

                <div className="stat-card" onClick={() => setActiveSection("inventory")} style={{ cursor: "pointer" }}>
                  <div className="stat-icon"><i className="fas fa-box"></i></div>
                  <div className="stat-content">
                    <h3>Inventory Items</h3>
                    <p className="stat-number">{inventory.length}</p>
                    <p className="stat-change">Supplies & low stock warnings</p>
                  </div>
                </div>
              </div>

              {/* Quick Actions Shortcuts */}
              <div className="dashboard-section">
                <h2>Quick Actions Control Deck</h2>
                <div style={{ display: "flex", gap: "15px", flexWrap: "wrap", marginTop: "15px" }}>
                  <button className="btn btn-primary" onClick={() => setActiveModal("addReptile")}>
                    <i className="fas fa-plus"></i> Add Specimen
                  </button>
                  <button className="btn btn-secondary" onClick={() => setActiveModal("addFeeding")}>
                    <i className="fas fa-utensils"></i> Log Feed
                  </button>
                  <button className="btn btn-secondary" onClick={() => setActiveModal("addBreeding")}>
                    <i className="fas fa-code-branch"></i> Add Pairing
                  </button>
                  <button className="btn btn-secondary" onClick={() => setActiveModal("addTask")}>
                    <i className="fas fa-tasks"></i> Schedule Task
                  </button>
                </div>
              </div>

              {/* Recent social activity shortcut */}
              <div className="dashboard-section" style={{ marginTop: "20px" }}>
                <h2>ReptiGram Community Snippets</h2>
                <p style={{ color: "var(--text-secondary)", marginBottom: "15px" }}>Stay in touch with updates from other breeders.</p>
                <div className="stats-grid" style={{ gridTemplateColumns: "1fr" }}>
                  {posts.slice(0, 2).map((post) => (
                    <div key={post.id} style={{ border: "1px solid var(--border-color)", padding: "15px", borderRadius: "8px", background: "var(--bg-secondary)" }}>
                      <strong style={{ color: "var(--primary-light)" }}>{post.authorName}</strong>
                      <p style={{ margin: "5px 0" }}>{post.content}</p>
                      <small style={{ color: "var(--text-light)" }}><i className="fas fa-thumbs-up"></i> {post.likesCount} likes</small>
                    </div>
                  ))}
                  <button className="btn btn-outline" style={{ marginTop: "10px" }} onClick={() => setActiveSection("social")}>
                    Go to Community Social Feed
                  </button>
                </div>
              </div>
            </div>
          </section>
        )}

        {/* ==================================================== */}
        {/* SECTION: REPTILES */}
        {/* ==================================================== */}
        {activeSection === "animals" && (
          <section className="content-section active">
            <div className="section-header" style={{ display: "flex", justifyContent: "space-between", alignItems: "center", flexWrap: "wrap", gap: "15px" }}>
              <div>
                <h1>My Reptiles Collection</h1>
                <p>Track weights, genetics, feeding regimes, and scan specimen barcodes.</p>
              </div>
              <button className="btn btn-primary" onClick={() => setActiveModal("addReptile")}>
                <i className="fas fa-plus"></i> Add Specimen
              </button>
            </div>

            <div className="dashboard-section" style={{ overflowX: "auto" }}>
              <table style={{ width: "100%", borderCollapse: "collapse", color: "var(--text-primary)" }}>
                <thead>
                  <tr style={{ borderBottom: "2px solid var(--border-color)", textAlign: "left" }}>
                    <th style={{ padding: "12px 8px" }}>Name</th>
                    <th style={{ padding: "12px 8px" }}>Species</th>
                    <th style={{ padding: "12px 8px" }}>Gender</th>
                    <th style={{ padding: "12px 8px" }}>Morph</th>
                    <th style={{ padding: "12px 8px" }}>Status</th>
                    <th style={{ padding: "12px 8px" }}>QR Code</th>
                    <th style={{ padding: "12px 8px", textAlign: "right" }}>Actions</th>
                  </tr>
                </thead>
                <tbody>
                  {reptiles.length === 0 ? (
                    <tr>
                      <td colSpan={7} style={{ padding: "30px", textAlign: "center", color: "var(--text-secondary)" }}>
                        No reptiles registered in your collection. Click "Add Specimen" to register your first reptile.
                      </td>
                    </tr>
                  ) : (
                    reptiles.map((rep) => (
                      <tr key={rep.id} style={{ borderBottom: "1px solid var(--border-color)" }}>
                        <td style={{ padding: "12px 8px", fontWeight: "600" }}>{rep.name}</td>
                        <td style={{ padding: "12px 8px" }}>{rep.species}</td>
                        <td style={{ padding: "12px 8px" }}>
                          <span style={{ color: rep.gender === "Female" ? "#ff4081" : "#2196f3" }}>
                            <i className={rep.gender === "Female" ? "fas fa-venus" : "fas fa-mars"}></i> {rep.gender}
                          </span>
                        </td>
                        <td style={{ padding: "12px 8px" }}>{rep.morph || "Normal"}</td>
                        <td style={{ padding: "12px 8px" }}>
                          <span className="plan-badge" style={{ backgroundColor: rep.status === "active" ? "#4caf50" : rep.status === "breeding" ? "#2196f3" : "#9e9e9e" }}>
                            {rep.status}
                          </span>
                        </td>
                        <td style={{ padding: "12px 8px" }}>
                          <button 
                            className="btn btn-outline" 
                            style={{ padding: "4px 8px", fontSize: "0.8rem" }}
                            onClick={() => setQrCodeData(`scalesyncpro://reptile/${rep.id}`)}
                          >
                            <i className="fas fa-qrcode"></i> Generate
                          </button>
                        </td>
                        <td style={{ padding: "12px 8px", textAlign: "right" }}>
                          <button className="btn btn-outline" style={{ color: "#f44336", borderColor: "#f44336" }} onClick={() => handleDeleteReptile(rep.id)}>
                            <i className="fas fa-trash"></i>
                          </button>
                        </td>
                      </tr>
                    ))
                  )}
                </tbody>
              </table>
            </div>

            {/* QR Code Modal Display */}
            {qrCodeData && (
              <div className="modal active" style={{ display: "flex", justifyContent: "center", alignItems: "center" }}>
                <div className="modal-content" style={{ maxWidth: "350px", textAlign: "center" }}>
                  <div className="modal-header">
                    <h2>Specimen QR Code</h2>
                    <button className="close-btn" onClick={() => setQrCodeData(null)}>&times;</button>
                  </div>
                  <div style={{ margin: "20px 0" }}>
                    <img 
                      src={`https://api.qrserver.com/v1/create-qr-code/?size=200x200&data=${encodeURIComponent(qrCodeData)}`}
                      alt="Reptile QR Code" 
                      style={{ border: "2px solid #ccc", padding: "10px", borderRadius: "8px" }}
                    />
                    <p style={{ marginTop: "10px", fontSize: "0.85rem", wordBreak: "break-all" }}>{qrCodeData}</p>
                  </div>
                  <button className="btn btn-primary" onClick={() => setQrCodeData(null)}>Dismiss</button>
                </div>
              </div>
            )}
          </section>
        )}

        {/* ==================================================== */}
        {/* SECTION: BREEDING LOGS */}
        {/* ==================================================== */}
        {activeSection === "breeding" && (
          <section className="content-section active">
            <div className="section-header" style={{ display: "flex", justifyContent: "space-between", alignItems: "center", flexWrap: "wrap", gap: "15px" }}>
              <div>
                <h1>Breeding Logs & Pairings</h1>
                <p>Plan visual genetics charts, record pairing logs, and trace lineage.</p>
              </div>
              <button className="btn btn-primary" onClick={() => setActiveModal("addBreeding")}>
                <i className="fas fa-plus"></i> Create Pairing
              </button>
            </div>

            <div className="dashboard-section" style={{ overflowX: "auto" }}>
              <table style={{ width: "100%", borderCollapse: "collapse", color: "var(--text-primary)" }}>
                <thead>
                  <tr style={{ borderBottom: "2px solid var(--border-color)", textAlign: "left" }}>
                    <th style={{ padding: "12px 8px" }}>Project / Pair Name</th>
                    <th style={{ padding: "12px 8px" }}>Sire (Male)</th>
                    <th style={{ padding: "12px 8px" }}>Dam (Female)</th>
                    <th style={{ padding: "12px 8px" }}>Pairing Date</th>
                    <th style={{ padding: "12px 8px" }}>Status</th>
                    <th style={{ padding: "12px 8px", textAlign: "right" }}>Actions</th>
                  </tr>
                </thead>
                <tbody>
                  {breedingProjects.length === 0 ? (
                    <tr>
                      <td colSpan={6} style={{ padding: "30px", textAlign: "center", color: "var(--text-secondary)" }}>
                        No active breeding projects. Click "Create Pairing" to get started.
                      </td>
                    </tr>
                  ) : (
                    breedingProjects.map((p) => (
                      <tr key={p.id} style={{ borderBottom: "1px solid var(--border-color)" }}>
                        <td style={{ padding: "12px 8px", fontWeight: "600" }}>{p.projectName}</td>
                        <td style={{ padding: "12px 8px" }}>{p.male}</td>
                        <td style={{ padding: "12px 8px" }}>{p.female}</td>
                        <td style={{ padding: "12px 8px" }}>{p.startDate}</td>
                        <td style={{ padding: "12px 8px" }}>
                          <span className="plan-badge" style={{ backgroundColor: p.status === "active" ? "#4caf50" : "#ff9800" }}>
                            {p.status}
                          </span>
                        </td>
                        <td style={{ padding: "12px 8px", textAlign: "right" }}>
                          <button className="btn btn-outline" style={{ color: "#f44336", borderColor: "#f44336" }} onClick={() => handleDeleteBreeding(p.id)}>
                            <i className="fas fa-trash"></i>
                          </button>
                        </td>
                      </tr>
                    ))
                  )}
                </tbody>
              </table>
            </div>
          </section>
        )}

        {/* ==================================================== */}
        {/* SECTION: SCHEDULE */}
        {/* ==================================================== */}
        {activeSection === "schedule" && (
          <section className="content-section active">
            <div className="section-header" style={{ display: "flex", justifyContent: "space-between", alignItems: "center", flexWrap: "wrap", gap: "15px" }}>
              <div>
                <h1>Feeding & Husbandry Schedules</h1>
                <p>Track feeding tasks, cleaning runs, and upcoming vet visits.</p>
              </div>
              <button className="btn btn-primary" onClick={() => setActiveModal("addTask")}>
                <i className="fas fa-plus"></i> Schedule Task
              </button>
            </div>

            <div className="dashboard-section">
              <div style={{ display: "flex", flexDirection: "column", gap: "12px" }}>
                {tasks.map((task) => (
                  <div key={task.id} style={{ display: "flex", justifyContent: "space-between", alignItems: "center", padding: "15px", borderRadius: "8px", border: "1px solid var(--border-color)", background: "var(--bg-primary)" }}>
                    <div>
                      <span className="plan-badge" style={{ marginRight: "10px", backgroundColor: "var(--primary-color)" }}>{task.taskType}</span>
                      <strong>{task.target}</strong>
                      <div style={{ color: "var(--text-secondary)", fontSize: "0.85rem", marginTop: "5px" }}>
                        <i className="fas fa-clock"></i> Due: {task.date} at {task.time}
                      </div>
                    </div>
                    <div>
                      <button 
                        className="btn btn-outline" 
                        style={{ color: "#4caf50", borderColor: "#4caf50", marginRight: "10px" }}
                        onClick={() => {
                          setTasks(tasks.filter(t => t.id !== task.id));
                          triggerNotification("Task marked as completed!");
                        }}
                      >
                        <i className="fas fa-check"></i> Complete
                      </button>
                      <button 
                        className="btn btn-outline" 
                        style={{ color: "#f44336", borderColor: "#f44336" }}
                        onClick={() => setTasks(tasks.filter(t => t.id !== task.id))}
                      >
                        <i className="fas fa-times"></i> Cancel
                      </button>
                    </div>
                  </div>
                ))}
              </div>
            </div>
          </section>
        )}

        {/* ==================================================== */}
        {/* SECTION: INVENTORY */}
        {/* ==================================================== */}
        {activeSection === "inventory" && (
          <section className="content-section active">
            <div className="section-header" style={{ display: "flex", justifyContent: "space-between", alignItems: "center", flexWrap: "wrap", gap: "15px" }}>
              <div>
                <h1>Food Supplies & Feed Inventory</h1>
                <p>Track prey sizes, quantities, and low stock thresholds.</p>
              </div>
              <button className="btn btn-primary" onClick={() => setActiveModal("addInventory")}>
                <i className="fas fa-plus"></i> Add Supplies
              </button>
            </div>

            <div className="dashboard-section" style={{ overflowX: "auto" }}>
              <table style={{ width: "100%", borderCollapse: "collapse", color: "var(--text-primary)" }}>
                <thead>
                  <tr style={{ borderBottom: "2px solid var(--border-color)", textAlign: "left" }}>
                    <th style={{ padding: "12px 8px" }}>Supply Item</th>
                    <th style={{ padding: "12px 8px" }}>Stock Level</th>
                    <th style={{ padding: "12px 8px" }}>Cost Basis</th>
                    <th style={{ padding: "12px 8px" }}>Status</th>
                    <th style={{ padding: "12px 8px", textAlign: "right" }}>Adjust Quantity</th>
                  </tr>
                </thead>
                <tbody>
                  {inventory.map((item) => {
                    const isLow = item.quantity <= item.alertLimit;
                    return (
                      <tr key={item.id} style={{ borderBottom: "1px solid var(--border-color)" }}>
                        <td style={{ padding: "12px 8px", fontWeight: "600" }}>{item.itemName}</td>
                        <td style={{ padding: "12px 8px" }}>{item.quantity} {item.unit}</td>
                        <td style={{ padding: "12px 8px" }}>${item.cost.toFixed(2)}</td>
                        <td style={{ padding: "12px 8px" }}>
                          <span className="plan-badge" style={{ backgroundColor: isLow ? "#f44336" : "#4caf50" }}>
                            {isLow ? "Low Stock" : "In Stock"}
                          </span>
                        </td>
                        <td style={{ padding: "12px 8px", textAlign: "right" }}>
                          <button 
                            className="btn btn-outline" 
                            style={{ padding: "4px 8px", marginRight: "5px" }}
                            onClick={() => {
                              setInventory(inventory.map(i => i.id === item.id ? { ...i, quantity: Math.max(0, i.quantity - 1) } : i));
                            }}
                          >
                            -
                          </button>
                          <button 
                            className="btn btn-outline" 
                            style={{ padding: "4px 8px" }}
                            onClick={() => {
                              setInventory(inventory.map(i => i.id === item.id ? { ...i, quantity: i.quantity + 1 } : i));
                            }}
                          >
                            +
                          </button>
                        </td>
                      </tr>
                    );
                  })}
                </tbody>
              </table>
            </div>
          </section>
        )}

        {/* ==================================================== */}
        {/* SECTION: COMMUNITY SOCIAL FEED */}
        {/* ==================================================== */}
        {activeSection === "social" && (
          <section className="content-section active">
            <div className="section-header" style={{ display: "flex", justifyContent: "space-between", alignItems: "center", flexWrap: "wrap", gap: "15px" }}>
              <div>
                <h1>ScaleSync Social Hub</h1>
                <p>Telemetry feed, analytics, and social node controls.</p>
              </div>
              <button className="btn btn-primary" onClick={() => setActiveModal("addPost")}>
                <i className="fas fa-paper-plane"></i> Write a Post
              </button>
            </div>

            <ScaleSyncSocialDashboard
              posts={posts}
              user={user}
              isAdmin={isAdmin}
              handleDeletePost={handleDeletePost}
              handleLikePost={handleLikePost}
              setActiveModal={setActiveModal}
              theme={theme}
            />
          </section>
        )}

        {/* ==================================================== */}
        {/* SECTION: MARKETPLACE */}
        {/* ==================================================== */}
        {activeSection === "marketplace" && (
          <section className="content-section active">
            <div className="section-header" style={{ display: "flex", justifyContent: "space-between", alignItems: "center", flexWrap: "wrap", gap: "15px" }}>
              <div>
                <h1>ScaleSync Marketplace</h1>
                <p>Buy and sell specimen stock within our verified breeding network.</p>
              </div>
              <button className="btn btn-primary" onClick={() => setActiveModal("addListing")}>
                <i className="fas fa-tag"></i> Create Listing
              </button>
            </div>

            <div className="stats-grid" style={{ gridTemplateColumns: "repeat(auto-fill, minmax(300px, 1fr))" }}>
              {listings.length === 0 ? (
                <div className="dashboard-section" style={{ gridColumn: "1 / -1", textAlign: "center", padding: "40px", color: "var(--text-secondary)" }}>
                  No active listings currently available.
                </div>
              ) : (
                listings.map((item) => (
                  <div key={item.id} className="dashboard-section" style={{ padding: "0", overflow: "hidden", display: "flex", flexDirection: "column" }}>
                    <div style={{ height: "200px", background: "var(--bg-tertiary)", position: "relative", display: "flex", alignItems: "center", justifyContent: "center", color: "var(--text-light)" }}>
                      {item.photoUrls && item.photoUrls.length > 0 ? (
                        <img 
                          src={item.photoUrls[0]} 
                          alt={item.title} 
                          style={{ width: "100%", height: "100%", objectFit: "cover" }} 
                        />
                      ) : (
                        <div style={{ textAlign: "center" }}>
                          <i className="fas fa-camera" style={{ fontSize: "3rem", marginBottom: "10px" }}></i>
                          <p>No specimen photo</p>
                        </div>
                      )}
                      <div style={{ position: "absolute", top: "15px", right: "15px", background: "rgba(0, 0, 0, 0.75)", color: "#00ff00", padding: "6px 12px", borderRadius: "20px", fontWeight: "bold", fontSize: "1.1rem" }}>
                        ${item.price}
                      </div>
                    </div>
                    
                    <div style={{ padding: "20px", flex: 1, display: "flex", flexDirection: "column", justifyContent: "space-between" }}>
                      <div>
                        <div style={{ display: "flex", justifyContent: "space-between", alignItems: "flex-start", marginBottom: "10px" }}>
                          <h2 style={{ fontSize: "1.3rem", margin: 0 }}>{item.title}</h2>
                          <span className="plan-badge" style={{ backgroundColor: item.status === "active" ? "#4caf50" : "#ff9800" }}>{item.status}</span>
                        </div>
                        
                        <div style={{ fontSize: "0.85rem", color: "var(--text-secondary)", display: "flex", gap: "10px", marginBottom: "10px" }}>
                          <span><strong>Species:</strong> {item.species}</span>
                          <span><strong>Morph:</strong> {item.morph || "Normal"}</span>
                        </div>
                        
                        <p style={{ color: "var(--text-primary)", fontSize: "0.95rem", margin: "10px 0 15px 0" }}>{item.description}</p>
                      </div>

                      <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", borderTop: "1px solid var(--border-color)", paddingTop: "15px" }}>
                        <small style={{ color: "var(--text-light)" }}>Seller UID: {item.uid.substring(0, 8)}...</small>
                        
                        <div style={{ display: "flex", gap: "8px" }}>
                          {item.status === "active" && item.uid !== user?.uid && (
                            <button 
                              className="btn btn-primary" 
                              style={{ padding: "6px 12px", fontSize: "0.85rem" }}
                              onClick={() => {
                                updateListingStatusAction(user.uid, item.id, "sold");
                                triggerNotification("Listing marked as sold!");
                                fetchData();
                              }}
                            >
                              Inquire / Buy
                            </button>
                          )}
                          {(item.uid === user?.uid || isAdmin) && (
                            <button 
                              className="btn btn-outline" 
                              style={{ color: "#f44336", borderColor: "#f44336", padding: "6px 12px", fontSize: "0.85rem" }}
                              onClick={() => handleDeleteListing(item.id)}
                            >
                              <i className="fas fa-trash"></i> Delete
                            </button>
                          )}
                        </div>
                      </div>
                    </div>
                  </div>
                ))
              )}
            </div>
          </section>
        )}

        {/* ==================================================== */}
        {/* SECTION: REPORTS */}
        {/* ==================================================== */}
        {activeSection === "reports" && (
          <section className="content-section active">
            <div className="section-header">
              <h1>Collection Reports & Charts</h1>
              <p>Visual reports tracking inventory distributions and expenses.</p>
            </div>

            <div className="stats-grid" style={{ gridTemplateColumns: "repeat(auto-fit, minmax(300px, 1fr))" }}>
              <div className="dashboard-section" style={{ textAlign: "center" }}>
                <h2>Collection Species Mix</h2>
                <div style={{ width: "100%", height: "250px", display: "flex", alignItems: "center", justifyContent: "center" }}>
                  {/* Clean SVG representation of a chart to avoid client hydration errors */}
                  <svg width="200" height="200" viewBox="0 0 200 200">
                    <circle cx="100" cy="100" r="80" fill="transparent" stroke="#2c5530" strokeWidth="40" strokeDasharray="250 500" />
                    <circle cx="100" cy="100" r="80" fill="transparent" stroke="#8bc34a" strokeWidth="40" strokeDasharray="150 500" strokeDashoffset="-250" />
                    <circle cx="100" cy="100" r="80" fill="transparent" stroke="#ff9800" strokeWidth="40" strokeDasharray="100 500" strokeDashoffset="-400" />
                  </svg>
                </div>
                <div style={{ display: "flex", justifyContent: "center", gap: "15px", fontSize: "0.85rem", marginTop: "15px" }}>
                  <span><i className="fas fa-circle" style={{ color: "#2c5530" }}></i> Ball Pythons (50%)</span>
                  <span><i className="fas fa-circle" style={{ color: "#8bc34a" }}></i> Geckos (30%)</span>
                  <span><i className="fas fa-circle" style={{ color: "#ff9800" }}></i> Others (20%)</span>
                </div>
              </div>

              <div className="dashboard-section" style={{ textAlign: "center" }}>
                <h2>Expense Breakdown</h2>
                <div style={{ width: "100%", height: "250px", display: "flex", alignItems: "center", justifyContent: "center" }}>
                  <svg width="200" height="200" viewBox="0 0 200 200">
                    <rect x="30" y="30" width="30" height="140" fill="#2c5530" />
                    <rect x="85" y="60" width="30" height="110" fill="#ff9800" />
                    <rect x="140" y="90" width="30" height="80" fill="#2196f3" />
                    <line x1="10" y1="170" x2="190" y2="170" stroke="var(--border-color)" strokeWidth="2" />
                  </svg>
                </div>
                <div style={{ display: "flex", justifyContent: "center", gap: "15px", fontSize: "0.85rem", marginTop: "15px" }}>
                  <span><i className="fas fa-square" style={{ color: "#2c5530" }}></i> Food (45%)</span>
                  <span><i className="fas fa-square" style={{ color: "#ff9800" }}></i> Enclosures (30%)</span>
                  <span><i className="fas fa-square" style={{ color: "#2196f3" }}></i> Vet (25%)</span>
                </div>
              </div>
            </div>
          </section>
        )}
      </main>

      {/* ==================================================== */}
      {/* MODALS */}
      {/* ==================================================== */}

      {/* MODAL: Add Reptile */}
      {activeModal === "addReptile" && (
        <div className="modal active" style={{ display: "flex" }}>
          <div className="modal-content">
            <div className="modal-header">
              <h2>Add Specimen</h2>
              <button className="close-btn" onClick={() => setActiveModal(null)}>&times;</button>
            </div>
            <form onSubmit={handleAddReptile} className="auth-form" style={{ marginTop: "15px" }}>
              <div className="form-row">
                <div className="form-group">
                  <label>Name</label>
                  <input 
                    type="text" 
                    value={reptileForm.name} 
                    onChange={(e) => setReptileForm({ ...reptileForm, name: e.target.value })}
                    placeholder="Luna" 
                    required 
                  />
                </div>
                <div className="form-group">
                  <label>Species</label>
                  <select 
                    value={reptileForm.species} 
                    onChange={(e) => setReptileForm({ ...reptileForm, species: e.target.value })}
                  >
                    <option value="Ball Python">Ball Python</option>
                    <option value="Leopard Gecko">Leopard Gecko</option>
                    <option value="Bearded Dragon">Bearded Dragon</option>
                    <option value="Corn Snake">Corn Snake</option>
                  </select>
                </div>
              </div>

              <div className="form-row">
                <div className="form-group">
                  <label>Gender</label>
                  <select 
                    value={reptileForm.gender} 
                    onChange={(e) => setReptileForm({ ...reptileForm, gender: e.target.value })}
                  >
                    <option value="Female">Female</option>
                    <option value="Male">Male</option>
                    <option value="Unknown">Unknown</option>
                  </select>
                </div>
                <div className="form-group">
                  <label>Morph / Genetics</label>
                  <input 
                    type="text" 
                    value={reptileForm.morph} 
                    onChange={(e) => setReptileForm({ ...reptileForm, morph: e.target.value })}
                    placeholder="Albino Piebald" 
                  />
                </div>
              </div>

              <div className="form-row">
                <div className="form-group">
                  <label>Birth Date</label>
                  <input 
                    type="date" 
                    value={reptileForm.birthDate} 
                    onChange={(e) => setReptileForm({ ...reptileForm, birthDate: e.target.value })}
                  />
                </div>
                <div className="form-group">
                  <label>Acquisition Date</label>
                  <input 
                    type="date" 
                    value={reptileForm.acquisitionDate} 
                    onChange={(e) => setReptileForm({ ...reptileForm, acquisitionDate: e.target.value })}
                  />
                </div>
              </div>

              <div className="form-group">
                <label>Notes</label>
                <textarea 
                  value={reptileForm.notes} 
                  onChange={(e) => setReptileForm({ ...reptileForm, notes: e.target.value })}
                  placeholder="Notes on dietary history or temperament..."
                ></textarea>
              </div>

              <div style={{ display: "flex", gap: "10px", justifyContent: "flex-end", marginTop: "20px" }}>
                <button type="button" className="btn btn-outline" onClick={() => setActiveModal(null)}>Cancel</button>
                <button type="submit" className="btn btn-primary">Save Specimen</button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* MODAL: Log Feeding */}
      {activeModal === "addFeeding" && (
        <div className="modal active" style={{ display: "flex" }}>
          <div className="modal-content" style={{ maxWidth: "450px" }}>
            <div className="modal-header">
              <h2>Log Feeding</h2>
              <button className="close-btn" onClick={() => setActiveModal(null)}>&times;</button>
            </div>
            <form onSubmit={handleAddFeedLog} style={{ marginTop: "15px" }}>
              <div className="form-group">
                <label>Reptile Specimen</label>
                <select 
                  value={selectedReptileForFeeding} 
                  onChange={(e) => setSelectedReptileForFeeding(e.target.value)}
                  required
                >
                  <option value="">Select a reptile</option>
                  {reptiles.map((r) => (
                    <option key={r.id} value={r.id}>{r.name} ({r.species})</option>
                  ))}
                </select>
              </div>

              <div className="form-group">
                <label>Prey Type</label>
                <input 
                  type="text" 
                  value={foodType} 
                  onChange={(e) => setFoodType(e.target.value)}
                  required 
                />
              </div>

              <div className="form-group">
                <label>Prey Weight (grams)</label>
                <input 
                  type="number" 
                  value={preyWeight} 
                  onChange={(e) => setPreyWeight(Number(e.target.value))}
                  required 
                />
              </div>

              <div style={{ display: "flex", gap: "10px", justifyContent: "flex-end", marginTop: "20px" }}>
                <button type="button" className="btn btn-outline" onClick={() => setActiveModal(null)}>Cancel</button>
                <button type="submit" className="btn btn-primary">Log Feeding</button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* MODAL: Add Breeding */}
      {activeModal === "addBreeding" && (
        <div className="modal active" style={{ display: "flex" }}>
          <div className="modal-content">
            <div className="modal-header">
              <h2>New Breeding Pair</h2>
              <button className="close-btn" onClick={() => setActiveModal(null)}>&times;</button>
            </div>
            <form onSubmit={handleAddBreeding} className="auth-form" style={{ marginTop: "15px" }}>
              <div className="form-group">
                <label>Project / Clutch Name</label>
                <input 
                  type="text" 
                  value={breedingForm.projectName} 
                  onChange={(e) => setBreedingForm({ ...breedingForm, projectName: e.target.value })}
                  placeholder="2026 Piebald Project" 
                  required 
                />
              </div>

              <div className="form-row">
                <div className="form-group">
                  <label>Male (Sire)</label>
                  <select 
                    value={breedingForm.male} 
                    onChange={(e) => setBreedingForm({ ...breedingForm, male: e.target.value })}
                    required
                  >
                    <option value="">Select male</option>
                    {reptiles.filter(r => r.gender === "Male" || r.gender === "Unknown").map(r => (
                      <option key={r.id} value={r.name}>{r.name} ({r.morph || "Normal"})</option>
                    ))}
                  </select>
                </div>
                <div className="form-group">
                  <label>Female (Dam)</label>
                  <select 
                    value={breedingForm.female} 
                    onChange={(e) => setBreedingForm({ ...breedingForm, female: e.target.value })}
                    required
                  >
                    <option value="">Select female</option>
                    {reptiles.filter(r => r.gender === "Female" || r.gender === "Unknown").map(r => (
                      <option key={r.id} value={r.name}>{r.name} ({r.morph || "Normal"})</option>
                    ))}
                  </select>
                </div>
              </div>

              <div className="form-group">
                <label>Pairing Date</label>
                <input 
                  type="date" 
                  value={breedingForm.startDate} 
                  onChange={(e) => setBreedingForm({ ...breedingForm, startDate: e.target.value })}
                  required 
                />
              </div>

              <div style={{ display: "flex", gap: "10px", justifyContent: "flex-end", marginTop: "20px" }}>
                <button type="button" className="btn btn-outline" onClick={() => setActiveModal(null)}>Cancel</button>
                <button type="submit" className="btn btn-primary">Start Project</button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* MODAL: Add Task */}
      {activeModal === "addTask" && (
        <div className="modal active" style={{ display: "flex" }}>
          <div className="modal-content" style={{ maxWidth: "450px" }}>
            <div className="modal-header">
              <h2>Schedule Task</h2>
              <button className="close-btn" onClick={() => setActiveModal(null)}>&times;</button>
            </div>
            <form onSubmit={handleAddTask} style={{ marginTop: "15px" }}>
              <div className="form-group">
                <label>Task Type</label>
                <select 
                  value={taskForm.taskType} 
                  onChange={(e) => setTaskForm({ ...taskForm, taskType: e.target.value })}
                >
                  <option value="Feeding">Feeding</option>
                  <option value="Clean Enclosure">Clean Enclosure</option>
                  <option value="Health Check">Health Check</option>
                  <option value="Breeding Introduce">Introduce Pair</option>
                </select>
              </div>

              <div className="form-group">
                <label>Target Specimen (Optional)</label>
                <input 
                  type="text" 
                  value={taskForm.target} 
                  onChange={(e) => setTaskForm({ ...taskForm, target: e.target.value })}
                  placeholder="Luna or General Enclosures" 
                />
              </div>

              <div className="form-row">
                <div className="form-group">
                  <label>Date</label>
                  <input 
                    type="date" 
                    value={taskForm.taskDate} 
                    onChange={(e) => setTaskForm({ ...taskForm, taskDate: e.target.value })}
                    required 
                  />
                </div>
                <div className="form-group">
                  <label>Time</label>
                  <input 
                    type="time" 
                    value={taskForm.taskTime} 
                    onChange={(e) => setTaskForm({ ...taskForm, taskTime: e.target.value })}
                    required 
                  />
                </div>
              </div>

              <div style={{ display: "flex", gap: "10px", justifyContent: "flex-end", marginTop: "20px" }}>
                <button type="button" className="btn btn-outline" onClick={() => setActiveModal(null)}>Cancel</button>
                <button type="submit" className="btn btn-primary">Schedule</button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* MODAL: Add Inventory Supplies */}
      {activeModal === "addInventory" && (
        <div className="modal active" style={{ display: "flex" }}>
          <div className="modal-content" style={{ maxWidth: "450px" }}>
            <div className="modal-header">
              <h2>Add Supplies / Feed Stock</h2>
              <button className="close-btn" onClick={() => setActiveModal(null)}>&times;</button>
            </div>
            <form onSubmit={handleAddInventory} style={{ marginTop: "15px" }}>
              <div className="form-group">
                <label>Item Name</label>
                <input 
                  type="text" 
                  value={inventoryForm.itemName} 
                  onChange={(e) => setInventoryForm({ ...inventoryForm, itemName: e.target.value })}
                  placeholder="Frozen Weaned Rats" 
                  required 
                />
              </div>

              <div className="form-row">
                <div className="form-group">
                  <label>Quantity</label>
                  <input 
                    type="number" 
                    value={inventoryForm.quantity} 
                    onChange={(e) => setInventoryForm({ ...inventoryForm, quantity: Number(e.target.value) })}
                    min="1" 
                    required 
                  />
                </div>
                <div className="form-group">
                  <label>Unit</label>
                  <input 
                    type="text" 
                    value={inventoryForm.unit} 
                    onChange={(e) => setInventoryForm({ ...inventoryForm, unit: e.target.value })}
                    placeholder="pcs" 
                    required 
                  />
                </div>
              </div>

              <div className="form-group">
                <label>Cost Basis Per Unit ($)</label>
                <input 
                  type="number" 
                  value={inventoryForm.costPerUnit} 
                  onChange={(e) => setInventoryForm({ ...inventoryForm, costPerUnit: Number(e.target.value) })}
                  step="0.01" 
                  required 
                />
              </div>

              <div style={{ display: "flex", gap: "10px", justifyContent: "flex-end", marginTop: "20px" }}>
                <button type="button" className="btn btn-outline" onClick={() => setActiveModal(null)}>Cancel</button>
                <button type="submit" className="btn btn-primary">Add Supplies</button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* MODAL: Add Post */}
      {activeModal === "addPost" && (
        <div className="modal active" style={{ display: "flex" }}>
          <div className="modal-content" style={{ maxWidth: "550px" }}>
            <div className="modal-header">
              <h2>Write a ReptiGram Post</h2>
              <button className="close-btn" onClick={() => setActiveModal(null)}>&times;</button>
            </div>
            <form onSubmit={handleAddPost} style={{ marginTop: "15px" }}>
              <div className="form-group">
                <label>What would you like to share?</label>
                <textarea 
                  value={postForm.content} 
                  onChange={(e) => setPostForm({ ...postForm, content: e.target.value })}
                  placeholder="Just had a successful lock on my Albino Piebald project!" 
                  style={{ height: "120px" }}
                  required
                ></textarea>
              </div>

              <div className="form-group">
                <label>Photo URL (Optional)</label>
                <input 
                  type="url" 
                  value={postForm.photoUrl} 
                  onChange={(e) => setPostForm({ ...postForm, photoUrl: e.target.value })}
                  placeholder="https://example.com/reptile.jpg" 
                />
              </div>

              <div style={{ display: "flex", gap: "10px", justifyContent: "flex-end", marginTop: "20px" }}>
                <button type="button" className="btn btn-outline" onClick={() => setActiveModal(null)}>Cancel</button>
                <button type="submit" className="btn btn-primary">Publish</button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* MODAL: Add Listing */}
      {activeModal === "addListing" && (
        <div className="modal active" style={{ display: "flex" }}>
          <div className="modal-content">
            <div className="modal-header">
              <h2>Marketplace Listing</h2>
              <button className="close-btn" onClick={() => setActiveModal(null)}>&times;</button>
            </div>
            <form onSubmit={handleAddListing} className="auth-form" style={{ marginTop: "15px" }}>
              <div className="form-group">
                <label>Title</label>
                <input 
                  type="text" 
                  value={listingForm.title} 
                  onChange={(e) => setListingForm({ ...listingForm, title: e.target.value })}
                  placeholder="2025 Albino Pied Female Ball Python" 
                  required 
                />
              </div>

              <div className="form-row">
                <div className="form-group">
                  <label>Price ($)</label>
                  <input 
                    type="number" 
                    value={listingForm.price} 
                    onChange={(e) => setListingForm({ ...listingForm, price: Number(e.target.value) })}
                    min="0" 
                    required 
                  />
                </div>
                <div className="form-group">
                  <label>Species</label>
                  <select 
                    value={listingForm.species} 
                    onChange={(e) => setListingForm({ ...listingForm, species: e.target.value })}
                  >
                    <option value="Ball Python">Ball Python</option>
                    <option value="Leopard Gecko">Leopard Gecko</option>
                    <option value="Bearded Dragon">Bearded Dragon</option>
                  </select>
                </div>
              </div>

              <div className="form-row">
                <div className="form-group">
                  <label>Morph</label>
                  <input 
                    type="text" 
                    value={listingForm.morph} 
                    onChange={(e) => setListingForm({ ...listingForm, morph: e.target.value })}
                    placeholder="Albino Piebald" 
                  />
                </div>
                <div className="form-group">
                  <label>Gender</label>
                  <select 
                    value={listingForm.gender} 
                    onChange={(e) => setListingForm({ ...listingForm, gender: e.target.value })}
                  >
                    <option value="Female">Female</option>
                    <option value="Male">Male</option>
                    <option value="Unknown">Unknown</option>
                  </select>
                </div>
              </div>

              <div className="form-group">
                <label>Description</label>
                <textarea 
                  value={listingForm.description} 
                  onChange={(e) => setListingForm({ ...listingForm, description: e.target.value })}
                  placeholder="Details on genetics, weight, feeding habits..."
                  required
                ></textarea>
              </div>

              <div className="form-group">
                <label>Photo URL (Optional)</label>
                <input 
                  type="url" 
                  value={listingForm.photoUrl} 
                  onChange={(e) => setListingForm({ ...listingForm, photoUrl: e.target.value })}
                  placeholder="https://example.com/specimen.jpg" 
                />
              </div>

              <div style={{ display: "flex", gap: "10px", justifyContent: "flex-end", marginTop: "20px" }}>
                <button type="button" className="btn btn-outline" onClick={() => setActiveModal(null)}>Cancel</button>
                <button type="submit" className="btn btn-primary">Publish Listing</button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* MODAL: Claim Manager (Local Development Roles Helper) */}
      {activeModal === "claimManager" && (
        <div className="modal active" style={{ display: "flex" }}>
          <div className="modal-content" style={{ maxWidth: "450px" }}>
            <div className="modal-header">
              <h2>Dev custom claims</h2>
              <button className="close-btn" onClick={() => setActiveModal(null)}>&times;</button>
            </div>
            <form onSubmit={handleSetAdminClaim} style={{ marginTop: "15px" }}>
              <p style={{ fontSize: "0.85rem", color: "var(--text-secondary)", marginBottom: "15px" }}>
                Assign admin custom claim attributes to users. (Allowed without token in local dev environments).
              </p>
              
              <div className="form-group">
                <label>Target User UID</label>
                <input 
                  type="text" 
                  value={targetUidClaim} 
                  onChange={(e) => setTargetUidClaim(e.target.value)}
                  placeholder="e.g. user-uid-hash-code" 
                  required 
                />
              </div>

              <div className="form-group">
                <label>Grant Admin Claim Status</label>
                <select 
                  value={targetAdminVal ? "true" : "false"} 
                  onChange={(e) => setTargetAdminVal(e.target.value === "true")}
                >
                  <option value="true">True (Grant Admin Privileges)</option>
                  <option value="false">False (Revoke Admin Privileges)</option>
                </select>
              </div>

              <div style={{ display: "flex", gap: "10px", justifyContent: "flex-end", marginTop: "20px" }}>
                <button type="button" className="btn btn-outline" onClick={() => setActiveModal(null)}>Cancel</button>
                <button type="submit" className="btn btn-primary">Assign Role Claim</button>
              </div>
            </form>
          </div>
        </div>
      )}
    </>
  );
}
