# Get screen resolution
res_w=$(xdpyinfo | awk '/dimensions/{print $2}' | cut -d'x' -f1)
res_h=$(xdpyinfo | awk '/dimensions/{print $2}' | cut -d'x' -f2)

# Compute margins if needed
w_margin=$((res_w / 4))
h_margin=$((res_h / 4))

# Launch wlogout with margins
wlogout -T $h_margin -B $h_margin