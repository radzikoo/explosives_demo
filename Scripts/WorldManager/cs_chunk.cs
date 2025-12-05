using Godot;
using System;
using System.Collections.Generic;

public partial class World : Node3D
{
	[Export] public Vector2 WorldSize { get; set; }
	[Export] public Vector3 ChunkSize { get; set; }
	[Export] public Vector3 TileSize { get; set; }

	private PackedScene CHUNK = GD.Load<PackedScene>("uid://cc1qdbduh3apw");

	private Dictionary<Vector2, Dictionary<string, Node>> world_chunks =
		new Dictionary<Vector2, Dictionary<string, Node>>();

	private LineEdit xc;
	private LineEdit yc;
	private LineEdit zc;
	private LineEdit chunk_x;
	private LineEdit chunk_y;

	public override void _Ready()
	{
		xc = GetNode<LineEdit>("TileController/HBoxContainer/XC");
		yc = GetNode<LineEdit>("TileController/HBoxContainer/YC");
		zc = GetNode<LineEdit>("TileController/HBoxContainer/ZC");
		chunk_x = GetNode<LineEdit>("TileController/HBoxContainer/ChunkX");
		chunk_y = GetNode<LineEdit>("TileController/HBoxContainer/ChunkY");

		_GenerateChunk();
		_GenerateChunkBorders();
	}

	private void _GenerateChunk()
	{
		for (int sx = 0; sx < (int)WorldSize.X; sx++)
		{
			for (int sy = 0; sy < (int)WorldSize.Y; sy++)
			{
				Node3D newChunk = CHUNK.Instantiate<Node3D>();

				newChunk.Set("chunk_size", ChunkSize);
				newChunk.Set("tile_size", TileSize);
				newChunk.Set("chunk_id", new Vector2(sx, sy));

				CallDeferred("add_child", newChunk);

				newChunk.Transform = new Transform3D(
					newChunk.Transform.Basis,
					new Vector3(ChunkSize.X * sx, 0, ChunkSize.Z * sy)
				);

				newChunk.Name = $"{sx};{sy}";

				world_chunks[new Vector2(sx, sy)] = new Dictionary<string, Node>()
				{
					{ "node", newChunk }
				};
			}
		}
	}

	private void _GenerateChunkBorders()
	{
		var chunkBorder = GetNode<MultiMeshInstance3D>("ChunkBorder");

		MultiMesh multimesh = new MultiMesh();
		chunkBorder.Multimesh = multimesh;

		multimesh.TransformFormat = MultiMesh.TransformFormatEnum.Transform3D;
		multimesh.InstanceCount = 40;

		var borderMesh = GD.Load<BoxMesh>("uid://db40pa6ftoee1");
		borderMesh.Size = new Vector3(WorldSize.X * ChunkSize.X, 50, 0);

		multimesh.Mesh = borderMesh;

		int mmi_count = 512;
		multimesh.InstanceCount = mmi_count;

		int index_x = 0;
		int index_z = 0;

		// X borders
		for (int cx = 0; cx <= (int)WorldSize.X; cx++)
		{
			Vector3 pos = new Vector3(cx * ChunkSize.X, 5, (WorldSize.X * ChunkSize.X) / 2);
			Transform3D transform = new Transform3D(
				new Basis(Vector3.Up, Mathf.DegToRad(-90)),
				pos
			);

			multimesh.SetInstanceTransform(index_x, transform);
			index_x++;
		}

		// Z borders
		for (int cz = 0; cz <= (int)WorldSize.Y; cz++)
		{
			Vector3 pos = new Vector3(
				(WorldSize.Y * ChunkSize.Z) / 2,
				5,
				cz * ChunkSize.Z
			);

			Transform3D transform = new Transform3D(
				new Basis(Vector3.Up, Mathf.DegToRad(-180)),
				pos
			);

			multimesh.SetInstanceTransform(index_z + index_x, transform);
			index_z++;
		}
	}

	private void _on_place_tile_pressed()
	{
		Vector2 given_id = new Vector2(
			int.Parse(chunk_x.Text),
			int.Parse(chunk_y.Text)
		);

		Vector3 given_xyz = new Vector3(
			int.Parse(xc.Text),
			int.Parse(yc.Text),
			int.Parse(zc.Text)
		);

		if (world_chunks.ContainsKey(given_id))
		{
			var target_chunk = world_chunks[given_id]["node"];
			target_chunk.Call("add_tile", given_xyz);
		}
	}

	private void _on_dest_tile_pressed()
	{
		Vector2 given_id = new Vector2(
			int.Parse(chunk_x.Text),
			int.Parse(chunk_y.Text)
		);

		Vector3 given_xyz = new Vector3(
			int.Parse(xc.Text),
			int.Parse(yc.Text),
			int.Parse(zc.Text)
		);

		if (world_chunks.ContainsKey(given_id))
		{
			var target_chunk = world_chunks[given_id]["node"];
			target_chunk.Call("remove_tile", given_xyz);
		}
	}

	private void _on_gennewchunk_pressed()
	{
		Vector2 given_id = new Vector2(
			int.Parse(chunk_x.Text),
			int.Parse(chunk_y.Text)
		);

		Node3D newChunk = CHUNK.Instantiate<Node3D>();

		newChunk.Set("chunk_size", ChunkSize);
		newChunk.Set("tile_size", TileSize);
		newChunk.Set("chunk_id", given_id);

		CallDeferred("add_child", newChunk);

		newChunk.Transform = new Transform3D(
			newChunk.Transform.Basis,
			new Vector3(
				ChunkSize.X * given_id.X,
				0,
				ChunkSize.Z * given_id.Y
			)
		);

		newChunk.Name = $"{given_id.X};{given_id.Y}";

		world_chunks[given_id] = new Dictionary<string, Node>() 
		{ 
			{ "node", newChunk } 
		};
	}

	private void _on_check_button_pressed()
	{
		GetNode("ChunkBorder").Set("visible",
			GetNode<CheckButton>("TileController/CheckButton").ButtonPressed
		);
	}

	public void place_tile(Vector3 xyz, Vector2 chunk_id)
	{
		if (world_chunks.ContainsKey(chunk_id))
		{
			Node target_chunk = world_chunks[chunk_id]["node"];

			Vector3 adjusted = new Vector3(
				xyz.X - (ChunkSize.X - chunk_id.X),
				xyz.Y,
				xyz.Z - (ChunkSize.Z - chunk_id.Y)
			);

			target_chunk.Call("add_tile", adjusted);
		}
	}

	public void destroy_tile(Vector3 xyz, Vector2 chunk_id)
	{
		if (!world_chunks.ContainsKey(chunk_id))
			return;

		Node target_chunk = world_chunks[chunk_id]["node"];

		Vector3 adjusted = new Vector3(
			xyz.X - (ChunkSize.X * chunk_id.X),
			xyz.Y,
			xyz.Z - (ChunkSize.Z * chunk_id.Y)
		);

		target_chunk.Call("remove_tile", adjusted);

		bool needNeighbour = false;
		Vector2 neighbour_id = chunk_id;

		int x_shift = 0;
		int z_shift = 0;

		// X edge check
		if (adjusted.X == 0)
		{
			x_shift = (int)ChunkSize.X - 1;
			neighbour_id.X -= 1;
			needNeighbour = true;
		}
		else if (adjusted.X == ChunkSize.X - 1)
		{
			x_shift = (int)ChunkSize.X - 1;
			neighbour_id.X += 1;
			needNeighbour = true;
		}

		// Z edge check
		if (adjusted.Z == 0)
		{
			z_shift = Mathf.Abs((int)ChunkSize.Z - (int)adjusted.Z) - 1;
			neighbour_id.Y -= 1;
			needNeighbour = true;
		}
		else if (adjusted.Z == ChunkSize.Z - 1)
		{
			z_shift = (int)adjusted.Z;
			neighbour_id.Y += 1;
			needNeighbour = true;
		}

		if (needNeighbour && world_chunks.ContainsKey(neighbour_id))
		{
			Node neighbour_chunk = world_chunks[neighbour_id]["node"];

			Vector3 nb_xyz = new Vector3(
				Mathf.Abs(adjusted.X - x_shift),
				adjusted.Y,
				Mathf.Abs(adjusted.Z - z_shift)
			);

			neighbour_chunk.Call("switch_tile_visibility", true, nb_xyz);
		}
	}
}
