# LandSandBoat API Use Cases

## Overview

This document provides practical use cases and implementation examples for building tools and applications around the LandSandBoat server.

## GM Management Dashboard

### Purpose
Web-based interface for game masters to manage the server, players, and game state.

### Features

#### 1. Player Management
**View Online Players**
```javascript
// Frontend: React component
async function OnlinePlayersList() {
  const response = await fetch('/api/v1/server/online');
  const { players } = await response.json();

  return (
    <table>
      <thead>
        <tr>
          <th>Character</th>
          <th>Job/Level</th>
          <th>Location</th>
          <th>Actions</th>
        </tr>
      </thead>
      <tbody>
        {players.map(player => (
          <tr key={player.charid}>
            <td>{player.charname}</td>
            <td>{player.mjob} {player.mlvl}</td>
            <td>{player.zone_name}</td>
            <td>
              <button onClick={() => teleportPlayer(player.charid)}>
                Teleport
              </button>
              <button onClick={() => kickPlayer(player.charid)}>
                Kick
              </button>
            </td>
          </tr>
        ))}
      </tbody>
    </table>
  );
}
```

**Character Search and Edit**
```javascript
// Search for character
async function searchCharacter(name) {
  const response = await fetch(
    `/api/v1/characters/search?name=${encodeURIComponent(name)}`
  );
  return await response.json();
}

// Teleport character
async function teleportPlayer(charid, zoneId, x, y, z) {
  const response = await fetch(
    `/api/v1/admin/characters/${charid}/teleport`,
    {
      method: 'PATCH',
      headers: {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        zone_id: zoneId,
        x, y, z
      })
    }
  );
  return await response.json();
}

// Give item to player
async function giveItem(charid, itemId, quantity) {
  const response = await fetch(
    `/api/v1/characters/${charid}/items`,
    {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({ item_id: itemId, quantity })
    }
  );
  return await response.json();
}
```

#### 2. Server Announcements
```javascript
// Send announcement to all players
async function sendAnnouncement(message) {
  const response = await fetch('/api/v1/admin/announce', {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${token}`,
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({ message })
  });

  const result = await response.json();
  alert(`Announcement sent to ${result.recipient_count} players`);
}

// Component
function AnnouncementPanel() {
  const [message, setMessage] = useState('');

  const handleSend = async () => {
    await sendAnnouncement(message);
    setMessage('');
  };

  return (
    <div>
      <h3>Server Announcement</h3>
      <textarea
        value={message}
        onChange={(e) => setMessage(e.target.value)}
        placeholder="Enter announcement message..."
      />
      <button onClick={handleSend}>Send to All Players</button>
    </div>
  );
}
```

#### 3. Ban Management
```javascript
// Ban player
async function banPlayer(accountId, durationHours, reason) {
  const response = await fetch('/api/v1/admin/bans', {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${token}`,
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({
      account_id: accountId,
      ban_type: 1,
      duration_hours: durationHours,
      reason
    })
  });
  return await response.json();
}

// View active bans
async function getActiveBans() {
  const response = await fetch('/api/v1/admin/bans', {
    headers: { 'Authorization': `Bearer ${token}` }
  });
  return await response.json();
}

// Component
function BanManagement() {
  const [bans, setBans] = useState([]);

  useEffect(() => {
    getActiveBans().then(setBans);
  }, []);

  return (
    <div>
      <h3>Active Bans</h3>
      <table>
        <thead>
          <tr>
            <th>Account</th>
            <th>Reason</th>
            <th>Expires</th>
            <th>Actions</th>
          </tr>
        </thead>
        <tbody>
          {bans.map(ban => (
            <tr key={ban.id}>
              <td>{ban.username}</td>
              <td>{ban.reason}</td>
              <td>{ban.expires_at || 'Permanent'}</td>
              <td>
                <button onClick={() => removeBan(ban.id)}>
                  Unban
                </button>
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}
```

## Player Profile Viewer

### Purpose
Public website for players to view character profiles, leaderboards, and statistics.

### Features

#### 1. Character Profile Page
```javascript
// Fetch complete character profile
async function getCharacterProfile(charid) {
  const [char, jobs, equipment, skills] = await Promise.all([
    fetch(`/api/v1/characters/${charid}`).then(r => r.json()),
    fetch(`/api/v1/characters/${charid}/jobs`).then(r => r.json()),
    fetch(`/api/v1/characters/${charid}/equipment`).then(r => r.json()),
    fetch(`/api/v1/characters/${charid}/skills`).then(r => r.json())
  ]);

  return { char, jobs, equipment, skills };
}

// Component
function CharacterProfile({ charid }) {
  const [profile, setProfile] = useState(null);

  useEffect(() => {
    getCharacterProfile(charid).then(setProfile);
  }, [charid]);

  if (!profile) return <div>Loading...</div>;

  return (
    <div className="character-profile">
      <header>
        <h1>{profile.char.charname}</h1>
        <div className="job-info">
          {profile.char.job.main.name} {profile.char.job.main.level} /
          {profile.char.job.sub.name} {profile.char.job.sub.level}
        </div>
      </header>

      <section className="stats">
        <h2>Stats</h2>
        <div className="stat-grid">
          <div>HP: {profile.char.stats.hp}</div>
          <div>MP: {profile.char.stats.mp}</div>
          <div>STR: {profile.char.stats.str}</div>
          <div>DEX: {profile.char.stats.dex}</div>
          <div>VIT: {profile.char.stats.vit}</div>
          <div>AGI: {profile.char.stats.agi}</div>
          <div>INT: {profile.char.stats.int}</div>
          <div>MND: {profile.char.stats.mnd}</div>
          <div>CHR: {profile.char.stats.chr}</div>
        </div>
      </section>

      <section className="equipment">
        <h2>Equipment</h2>
        <div className="equipment-grid">
          {Object.entries(profile.equipment.equipment).map(([slot, item]) => (
            <div key={slot} className="equipment-slot">
              <div className="slot-name">{slot}</div>
              <div className="item-name">{item.name}</div>
              {item.damage && <div>DMG: {item.damage}</div>}
              {item.def && <div>DEF: {item.def}</div>}
            </div>
          ))}
        </div>
      </section>

      <section className="jobs">
        <h2>Job Levels</h2>
        <div className="job-list">
          {Object.entries(profile.jobs.jobs).map(([job, data]) => (
            <div key={job} className="job-entry">
              <span className="job-name">{job.toUpperCase()}</span>
              <span className="job-level">{data.level}</span>
            </div>
          ))}
        </div>
      </section>
    </div>
  );
}
```

#### 2. Leaderboards
```javascript
// Fetch leaderboard data
async function getLeaderboard(type, options = {}) {
  const params = new URLSearchParams(options);
  const response = await fetch(
    `/api/v1/leaderboards/${type}?${params}`
  );
  return await response.json();
}

// Component
function Leaderboard() {
  const [leaderboardType, setLeaderboardType] = useState('levels');
  const [data, setData] = useState([]);

  useEffect(() => {
    getLeaderboard(leaderboardType).then(result => {
      setData(result.leaderboard);
    });
  }, [leaderboardType]);

  return (
    <div>
      <h2>Leaderboards</h2>
      <select
        value={leaderboardType}
        onChange={(e) => setLeaderboardType(e.target.value)}
      >
        <option value="levels">Highest Level</option>
        <option value="wealth">Richest Players</option>
        <option value="crafting">Master Crafters</option>
      </select>

      <table>
        <thead>
          <tr>
            <th>Rank</th>
            <th>Character</th>
            <th>Value</th>
          </tr>
        </thead>
        <tbody>
          {data.map((entry, index) => (
            <tr key={entry.charid}>
              <td>{index + 1}</td>
              <td>
                <a href={`/character/${entry.charid}`}>
                  {entry.charname}
                </a>
              </td>
              <td>{entry.value || entry.mlvl || entry.gil}</td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}
```

## Market Price Tracker

### Purpose
Track auction house prices, analyze trends, and alert users to deals.

### Features

#### 1. Price History Viewer
```javascript
// Fetch price history
async function getItemPriceHistory(itemId, days = 30) {
  const response = await fetch(
    `/api/v1/auction/history?item_id=${itemId}&days=${days}`
  );
  return await response.json();
}

// Component with chart
import { LineChart, Line, XAxis, YAxis, Tooltip } from 'recharts';

function PriceHistoryChart({ itemId }) {
  const [history, setHistory] = useState(null);

  useEffect(() => {
    getItemPriceHistory(itemId).then(setHistory);
  }, [itemId]);

  if (!history) return <div>Loading...</div>;

  return (
    <div>
      <h3>{history.item_name} - Price History</h3>
      <div className="stats">
        <div>Average: {history.statistics.average_price.toLocaleString()} gil</div>
        <div>Min: {history.statistics.min_price.toLocaleString()} gil</div>
        <div>Max: {history.statistics.max_price.toLocaleString()} gil</div>
        <div>Total Sales: {history.statistics.total_sales}</div>
      </div>

      <LineChart width={800} height={400} data={history.daily_averages}>
        <XAxis dataKey="date" />
        <YAxis />
        <Tooltip />
        <Line
          type="monotone"
          dataKey="avg_price"
          stroke="#8884d8"
          name="Average Price"
        />
      </LineChart>
    </div>
  );
}
```

#### 2. Current Listings
```javascript
// Fetch current listings
async function getCurrentListings(itemId) {
  const response = await fetch(`/api/v1/auction/item/${itemId}`);
  return await response.json();
}

// Component
function ItemListings({ itemId }) {
  const [listings, setListings] = useState([]);

  useEffect(() => {
    getCurrentListings(itemId).then(setListings);
  }, [itemId]);

  return (
    <div>
      <h3>Current Listings</h3>
      <table>
        <thead>
          <tr>
            <th>Quantity</th>
            <th>Price</th>
            <th>Per Unit</th>
            <th>Seller</th>
          </tr>
        </thead>
        <tbody>
          {listings.map(listing => (
            <tr key={listing.listing_id}>
              <td>{listing.quantity}</td>
              <td>{listing.price.toLocaleString()} gil</td>
              <td>{listing.price_per_unit.toFixed(2)} gil</td>
              <td>{listing.seller}</td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}
```

#### 3. Price Alerts
```javascript
// Backend: Check for price alerts
async function checkPriceAlerts() {
  // Get all user alerts
  const alerts = await db.query(
    'SELECT * FROM user_price_alerts WHERE active = 1'
  );

  for (const alert of alerts) {
    // Check current price
    const result = await db.query(`
      SELECT MIN(sell_price) as lowest_price
      FROM auction_house
      WHERE itemid = ? AND sale = 0
    `, [alert.item_id]);

    const currentPrice = result[0].lowest_price;

    // If price meets target, notify user
    if (currentPrice && currentPrice <= alert.target_price) {
      await sendNotification(alert.user_id, {
        type: 'price_alert',
        item_id: alert.item_id,
        current_price: currentPrice,
        target_price: alert.target_price
      });

      // Disable alert
      await db.query(
        'UPDATE user_price_alerts SET active = 0 WHERE id = ?',
        [alert.id]
      );
    }
  }
}

// Run every 5 minutes
setInterval(checkPriceAlerts, 5 * 60 * 1000);
```

## Crafting Calculator

### Purpose
Help players calculate crafting costs and profits.

### Features

#### 1. Recipe Lookup
```javascript
// Get recipe with current market prices
async function getRecipeWithPrices(recipeId) {
  const recipe = await fetch(`/api/v1/recipes/${recipeId}`)
    .then(r => r.json());

  // Get current prices for all ingredients
  const ingredientPrices = await Promise.all(
    recipe.ingredients.map(async (ing) => {
      const market = await fetch(`/api/v1/items/${ing.item_id}/market`)
        .then(r => r.json());
      return {
        ...ing,
        current_price: market.market.lowest_price,
        avg_price: market.market.average_price
      };
    })
  );

  // Get result item price
  const resultMarket = await fetch(
    `/api/v1/items/${recipe.result.item_id}/market`
  ).then(r => r.json());

  return {
    ...recipe,
    ingredients: ingredientPrices,
    result_price: resultMarket.market.lowest_price,
    profit: calculateProfit(ingredientPrices, resultMarket.market.lowest_price)
  };
}

function calculateProfit(ingredients, resultPrice) {
  const cost = ingredients.reduce(
    (sum, ing) => sum + (ing.current_price * ing.quantity),
    0
  );
  return resultPrice - cost;
}

// Component
function RecipeCalculator({ recipeId }) {
  const [recipe, setRecipe] = useState(null);

  useEffect(() => {
    getRecipeWithPrices(recipeId).then(setRecipe);
  }, [recipeId]);

  if (!recipe) return <div>Loading...</div>;

  const profitPercentage = (recipe.profit / recipe.result_price * 100).toFixed(2);

  return (
    <div>
      <h3>Recipe: {recipe.result.name}</h3>

      <section>
        <h4>Ingredients</h4>
        <table>
          <thead>
            <tr>
              <th>Item</th>
              <th>Qty</th>
              <th>Price Each</th>
              <th>Total</th>
            </tr>
          </thead>
          <tbody>
            {recipe.ingredients.map(ing => (
              <tr key={ing.item_id}>
                <td>{ing.name}</td>
                <td>{ing.quantity}</td>
                <td>{ing.current_price.toLocaleString()} gil</td>
                <td>{(ing.current_price * ing.quantity).toLocaleString()} gil</td>
              </tr>
            ))}
          </tbody>
        </table>
      </section>

      <section>
        <h4>Profit Analysis</h4>
        <div className="profit-summary">
          <div>Result Price: {recipe.result_price.toLocaleString()} gil</div>
          <div>Total Cost: {
            recipe.ingredients.reduce((sum, ing) =>
              sum + (ing.current_price * ing.quantity), 0
            ).toLocaleString()
          } gil</div>
          <div className={recipe.profit > 0 ? 'profit-positive' : 'profit-negative'}>
            Profit: {recipe.profit.toLocaleString()} gil ({profitPercentage}%)
          </div>
        </div>
      </section>
    </div>
  );
}
```

#### 2. Profit Rankings
```javascript
// Backend: Calculate all recipe profits
async function calculateAllRecipeProfits() {
  const recipes = await db.query('SELECT ID FROM synth_recipes');
  const profits = [];

  for (const recipe of recipes) {
    const data = await getRecipeWithPrices(recipe.ID);
    if (data.profit > 0) {
      profits.push({
        recipe_id: recipe.ID,
        result_name: data.result.name,
        profit: data.profit,
        profit_percentage: (data.profit / data.result_price * 100)
      });
    }
  }

  // Sort by profit
  profits.sort((a, b) => b.profit - a.profit);

  return profits;
}

// Component
function ProfitableRecipes() {
  const [recipes, setRecipes] = useState([]);

  useEffect(() => {
    fetch('/api/v1/recipes/profitable')
      .then(r => r.json())
      .then(setRecipes);
  }, []);

  return (
    <div>
      <h2>Most Profitable Recipes</h2>
      <table>
        <thead>
          <tr>
            <th>Recipe</th>
            <th>Profit</th>
            <th>Margin</th>
          </tr>
        </thead>
        <tbody>
          {recipes.map(recipe => (
            <tr key={recipe.recipe_id}>
              <td>
                <a href={`/recipe/${recipe.recipe_id}`}>
                  {recipe.result_name}
                </a>
              </td>
              <td>{recipe.profit.toLocaleString()} gil</td>
              <td>{recipe.profit_percentage.toFixed(2)}%</td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}
```

## Monster Database

### Purpose
Comprehensive database of monsters with drop rates and locations.

### Features

#### 1. Monster Search
```javascript
// Search monsters
async function searchMonsters(query) {
  const response = await fetch(
    `/api/v1/mobs/search?name=${encodeURIComponent(query)}`
  );
  return await response.json();
}

// Component
function MonsterSearch() {
  const [query, setQuery] = useState('');
  const [results, setResults] = useState([]);

  const handleSearch = async () => {
    const data = await searchMonsters(query);
    setResults(data.results);
  };

  return (
    <div>
      <input
        type="text"
        value={query}
        onChange={(e) => setQuery(e.target.value)}
        placeholder="Search monsters..."
      />
      <button onClick={handleSearch}>Search</button>

      <div className="results">
        {results.map(mob => (
          <div key={mob.mob_id} className="mob-card">
            <h3>{mob.mob_name}</h3>
            <div>Level: {mob.level.min}-{mob.level.max}</div>
            <div>Zone: {mob.zone_name}</div>
            <a href={`/mob/${mob.mob_id}`}>View Details</a>
          </div>
        ))}
      </div>
    </div>
  );
}
```

#### 2. Drop List Viewer
```javascript
// Get mob drops
async function getMobDrops(mobId) {
  const response = await fetch(`/api/v1/mobs/${mobId}/drops`);
  return await response.json();
}

// Component
function MobDropList({ mobId }) {
  const [drops, setDrops] = useState([]);

  useEffect(() => {
    getMobDrops(mobId).then(data => setDrops(data.drops));
  }, [mobId]);

  return (
    <div>
      <h3>Drops</h3>
      <table>
        <thead>
          <tr>
            <th>Item</th>
            <th>Drop Rate</th>
            <th>Type</th>
          </tr>
        </thead>
        <tbody>
          {drops.map(drop => (
            <tr key={drop.item_id}>
              <td>
                <a href={`/item/${drop.item_id}`}>
                  {drop.item_name}
                </a>
              </td>
              <td>{drop.drop_percent}%</td>
              <td>{drop.drop_type_name}</td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}
```

#### 3. Item Drop Sources
```javascript
// Find where item drops
async function getItemDropSources(itemId) {
  const response = await fetch(`/api/v1/items/${itemId}/drops-from`);
  return await response.json();
}

// Component
function ItemDropSources({ itemId }) {
  const [sources, setSources] = useState([]);

  useEffect(() => {
    getItemDropSources(itemId).then(data => setSources(data.sources));
  }, [itemId]);

  return (
    <div>
      <h3>Where to Get This Item</h3>
      <table>
        <thead>
          <tr>
            <th>Monster</th>
            <th>Level</th>
            <th>Zone</th>
            <th>Drop Rate</th>
          </tr>
        </thead>
        <tbody>
          {sources.map(source => (
            <tr key={source.mob_id}>
              <td>
                <a href={`/mob/${source.mob_id}`}>
                  {source.mob_name}
                </a>
              </td>
              <td>{source.level}</td>
              <td>{source.zone_name}</td>
              <td>{source.drop_percent}%</td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}
```

## Server Statistics Dashboard

### Purpose
Real-time server statistics and analytics.

### Features

#### 1. Server Overview
```javascript
// Fetch server statistics
async function getServerStats() {
  const response = await fetch('/api/v1/server/status');
  return await response.json();
}

// Component
function ServerDashboard() {
  const [stats, setStats] = useState(null);

  useEffect(() => {
    // Initial fetch
    getServerStats().then(setStats);

    // Update every 30 seconds
    const interval = setInterval(() => {
      getServerStats().then(setStats);
    }, 30000);

    return () => clearInterval(interval);
  }, []);

  if (!stats) return <div>Loading...</div>;

  return (
    <div className="dashboard">
      <div className="stat-card">
        <h3>Online Players</h3>
        <div className="stat-value">{stats.players.online}</div>
        <div className="stat-label">Peak Today: {stats.players.peak_today}</div>
      </div>

      <div className="stat-card">
        <h3>Total Accounts</h3>
        <div className="stat-value">{stats.players.total_accounts}</div>
      </div>

      <div className="stat-card">
        <h3>Total Characters</h3>
        <div className="stat-value">{stats.players.total_characters}</div>
      </div>

      <div className="stat-card">
        <h3>Server Uptime</h3>
        <div className="stat-value">{stats.uptime_formatted}</div>
      </div>
    </div>
  );
}
```

#### 2. Activity Graphs
```javascript
// Backend: Generate activity data
async function getActivityData(days = 30) {
  const result = await db.query(`
    SELECT
      DATE(login_time) as date,
      COUNT(DISTINCT accid) as unique_accounts,
      COUNT(*) as total_logins
    FROM account_ip_record
    WHERE login_time > NOW() - INTERVAL ? DAY
    GROUP BY date
    ORDER BY date
  `, [days]);

  return result;
}

// Component
import { BarChart, Bar, XAxis, YAxis, Tooltip } from 'recharts';

function ActivityGraph() {
  const [data, setData] = useState([]);

  useEffect(() => {
    fetch('/api/v1/server/activity?days=30')
      .then(r => r.json())
      .then(setData);
  }, []);

  return (
    <div>
      <h3>Daily Active Users (Last 30 Days)</h3>
      <BarChart width={800} height={400} data={data}>
        <XAxis dataKey="date" />
        <YAxis />
        <Tooltip />
        <Bar dataKey="unique_accounts" fill="#8884d8" name="Active Accounts" />
      </BarChart>
    </div>
  );
}
```

#### 3. Zone Population
```javascript
// WebSocket connection for real-time updates
function ZonePopulation() {
  const [zones, setZones] = useState([]);

  useEffect(() => {
    const ws = new WebSocket('ws://localhost:5000/ws/server');

    ws.onmessage = (event) => {
      const message = JSON.parse(event.data);

      if (message.event === 'zone_population') {
        setZones(message.data);
      }
    };

    return () => ws.close();
  }, []);

  return (
    <div>
      <h3>Zone Population</h3>
      <table>
        <thead>
          <tr>
            <th>Zone</th>
            <th>Players</th>
          </tr>
        </thead>
        <tbody>
          {zones.map(zone => (
            <tr key={zone.zone_id}>
              <td>{zone.zone_name}</td>
              <td>{zone.player_count}</td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}
```

## Mobile Companion App

### Purpose
Mobile app for checking character status, market prices, and server info.

### Features

#### 1. Character Quick View
```javascript
// React Native component
import { View, Text, ScrollView } from 'react-native';

function CharacterQuickView({ charid }) {
  const [char, setChar] = useState(null);

  useEffect(() => {
    fetch(`${API_URL}/characters/${charid}`)
      .then(r => r.json())
      .then(setChar);
  }, [charid]);

  if (!char) return <Text>Loading...</Text>;

  return (
    <ScrollView>
      <View style={styles.header}>
        <Text style={styles.name}>{char.charname}</Text>
        <Text style={styles.job}>
          {char.job.main.name} {char.job.main.level}
        </Text>
      </View>

      <View style={styles.stats}>
        <StatRow label="HP" value={char.stats.hp} />
        <StatRow label="MP" value={char.stats.mp} />
        <StatRow label="Location" value={char.location.zone_name} />
        <StatRow label="Playtime" value={char.playtime_formatted} />
      </View>
    </ScrollView>
  );
}
```

#### 2. Market Price Lookup
```javascript
// React Native component
import { View, TextInput, FlatList } from 'react-native';

function MarketSearch() {
  const [query, setQuery] = useState('');
  const [results, setResults] = useState([]);

  const search = async () => {
    const response = await fetch(
      `${API_URL}/items/search?name=${encodeURIComponent(query)}`
    );
    const data = await response.json();
    setResults(data.results);
  };

  return (
    <View>
      <TextInput
        value={query}
        onChangeText={setQuery}
        onSubmitEditing={search}
        placeholder="Search items..."
      />

      <FlatList
        data={results}
        keyExtractor={item => item.item_id.toString()}
        renderItem={({ item }) => (
          <ItemCard
            name={item.name}
            price={item.current_price}
            onPress={() => navigation.navigate('ItemDetails', { id: item.item_id })}
          />
        )}
      />
    </View>
  );
}
```

## Discord Bot Integration

### Purpose
Discord bot for server status, character lookup, and notifications.

### Features

#### 1. Server Status Command
```javascript
// Discord.js bot
const { Client, Intents } = require('discord.js');
const client = new Client({ intents: [Intents.FLAGS.GUILDS] });

client.on('interactionCreate', async interaction => {
  if (!interaction.isCommand()) return;

  if (interaction.commandName === 'serverstatus') {
    const stats = await fetch(`${API_URL}/server/status`)
      .then(r => r.json());

    const embed = {
      title: 'Server Status',
      color: 0x00ff00,
      fields: [
        { name: 'Online Players', value: stats.players.online.toString(), inline: true },
        { name: 'Peak Today', value: stats.players.peak_today.toString(), inline: true },
        { name: 'Uptime', value: stats.uptime_formatted, inline: true }
      ],
      timestamp: new Date()
    };

    await interaction.reply({ embeds: [embed] });
  }
});
```

#### 2. Character Lookup Command
```javascript
client.on('interactionCreate', async interaction => {
  if (!interaction.isCommand()) return;

  if (interaction.commandName === 'character') {
    const name = interaction.options.getString('name');

    const results = await fetch(
      `${API_URL}/characters/search?name=${encodeURIComponent(name)}`
    ).then(r => r.json());

    if (results.total === 0) {
      await interaction.reply('Character not found.');
      return;
    }

    const char = results.results[0];
    const embed = {
      title: char.charname,
      color: 0x0099ff,
      fields: [
        { name: 'Job', value: `${char.mjob} ${char.mlvl}`, inline: true },
        { name: 'Nation', value: char.nation, inline: true }
      ]
    };

    await interaction.reply({ embeds: [embed] });
  }
});
```

## Best Practices

### 1. Caching Strategy
```javascript
// Use Redis for caching
const redis = require('redis');
const client = redis.createClient();

async function getCachedData(key, fetchFn, ttl = 300) {
  // Try cache first
  const cached = await client.get(key);
  if (cached) {
    return JSON.parse(cached);
  }

  // Fetch fresh data
  const data = await fetchFn();

  // Cache for future requests
  await client.setex(key, ttl, JSON.stringify(data));

  return data;
}

// Usage
app.get('/api/v1/server/status', async (req, res) => {
  const stats = await getCachedData(
    'server:status',
    () => getServerStats(),
    60  // Cache for 1 minute
  );
  res.json(stats);
});
```

### 2. Rate Limiting
```javascript
const rateLimit = require('express-rate-limit');

const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100 // limit each IP to 100 requests per windowMs
});

app.use('/api/', limiter);
```

### 3. Error Handling
```javascript
// Centralized error handler
app.use((err, req, res, next) => {
  console.error(err.stack);

  res.status(err.status || 500).json({
    error: true,
    code: err.code || 'INTERNAL_ERROR',
    message: err.message || 'An error occurred'
  });
});

// Usage in routes
app.get('/api/v1/characters/:id', async (req, res, next) => {
  try {
    const char = await getCharacter(req.params.id);

    if (!char) {
      const error = new Error('Character not found');
      error.status = 404;
      error.code = 'NOT_FOUND';
      throw error;
    }

    res.json(char);
  } catch (error) {
    next(error);
  }
});
```

### 4. Input Validation
```javascript
const { body, param, validationResult } = require('express-validator');

app.post('/api/v1/admin/announce',
  body('message').isLength({ min: 1, max: 500 }),
  async (req, res) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    // Process announcement
    await sendAnnouncement(req.body.message);
    res.json({ success: true });
  }
);
```
