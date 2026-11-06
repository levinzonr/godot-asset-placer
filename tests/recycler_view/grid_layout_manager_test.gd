extends GdUnitTestSuite

const LayoutManager = preload(
	"res://addons/asset_placer/ui/components/recycler_view/recycler_view_layout_manager.gd"
)
const GridLayout = preload(
	"res://addons/asset_placer/ui/components/recycler_view/grid_layout_manager.gd"
)
const VIEWPORT_SIZE := Vector2(320.0, 200.0)

var _layout: GridLayout


func before_test() -> void:
	_layout = GridLayout.new()
	_layout.span_count = 3
	_layout.item_height = 100.0
	_layout.spacing = Vector2(10.0, 8.0)


func test_implements_layout_contract() -> void:
	var layout: LayoutManager = _layout
	assert_vector(layout.get_content_size(10, VIEWPORT_SIZE)).is_equal(Vector2(320.0, 424.0))
	_assert_rect(layout.get_item_rect(4, 10, VIEWPORT_SIZE), Rect2(110.0, 108.0, 100.0, 100.0))
	assert_vector(layout.get_visible_range(10, VIEWPORT_SIZE, 108.0)).is_equal(Vector2i(3, 9))


func test_empty_data_has_no_geometry() -> void:
	for item_count in [0, -5]:
		assert_vector(_layout.get_content_size(item_count, VIEWPORT_SIZE)).is_equal(Vector2.ZERO)
		_assert_rect(_layout.get_item_rect(0, item_count, VIEWPORT_SIZE), Rect2())
		assert_vector(_layout.get_visible_range(item_count, VIEWPORT_SIZE, 0.0)).is_equal(
			Vector2i.ZERO
		)


func test_content_height_counts_partial_rows_without_a_trailing_gap() -> void:
	for item_count in [1, 2, 3]:
		assert_vector(_layout.get_content_size(item_count, VIEWPORT_SIZE)).is_equal(
			Vector2(320.0, 100.0)
		)
	for item_count in [4, 5, 6]:
		assert_vector(_layout.get_content_size(item_count, VIEWPORT_SIZE)).is_equal(
			Vector2(320.0, 208.0)
		)
	assert_vector(_layout.get_content_size(10, VIEWPORT_SIZE)).is_equal(Vector2(320.0, 424.0))


func test_zero_spacing() -> void:
	_layout.spacing = Vector2.ZERO
	var viewport := Vector2(300.0, 100.0)
	assert_vector(_layout.get_content_size(7, viewport)).is_equal(Vector2(300.0, 300.0))
	_assert_rect(_layout.get_item_rect(4, 7, viewport), Rect2(100.0, 100.0, 100.0, 100.0))
	assert_vector(_layout.get_visible_range(7, viewport, 100.0)).is_equal(Vector2i(3, 6))


func test_single_column_fills_the_width_without_horizontal_gaps() -> void:
	_layout.span_count = 1
	_layout.spacing.x = 500.0
	assert_vector(_layout.get_content_size(3, VIEWPORT_SIZE)).is_equal(Vector2(320.0, 316.0))
	_assert_rect(_layout.get_item_rect(2, 3, VIEWPORT_SIZE), Rect2(0.0, 216.0, 320.0, 100.0))
	assert_vector(_layout.get_visible_range(3, VIEWPORT_SIZE, 108.0)).is_equal(Vector2i(1, 3))


func test_item_rects_are_row_major_in_content_coordinates() -> void:
	_assert_rect(_layout.get_item_rect(0, 10, VIEWPORT_SIZE), Rect2(0.0, 0.0, 100.0, 100.0))
	_assert_rect(_layout.get_item_rect(2, 10, VIEWPORT_SIZE), Rect2(220.0, 0.0, 100.0, 100.0))
	_assert_rect(_layout.get_item_rect(3, 10, VIEWPORT_SIZE), Rect2(0.0, 108.0, 100.0, 100.0))
	_assert_rect(_layout.get_item_rect(4, 10, VIEWPORT_SIZE), Rect2(110.0, 108.0, 100.0, 100.0))


func test_invalid_positions_return_empty_rectangles() -> void:
	for position in [-1, 10, 100]:
		_assert_rect(_layout.get_item_rect(position, 10, VIEWPORT_SIZE), Rect2())


func test_partial_final_row_keeps_column_width_and_excludes_missing_items() -> void:
	_assert_rect(_layout.get_item_rect(9, 10, VIEWPORT_SIZE), Rect2(0.0, 324.0, 100.0, 100.0))
	assert_vector(_layout.get_visible_range(10, VIEWPORT_SIZE, 324.0)).is_equal(Vector2i(9, 10))


func test_width_changes_recalculate_columns_without_changing_row_height() -> void:
	var wider_viewport := Vector2(620.0, 200.0)
	_assert_rect(_layout.get_item_rect(4, 10, wider_viewport), Rect2(210.0, 108.0, 200.0, 100.0))
	assert_vector(_layout.get_content_size(10, wider_viewport)).is_equal(Vector2(620.0, 424.0))
	assert_vector(_layout.get_visible_range(10, wider_viewport, 108.0)).is_equal(Vector2i(3, 9))


func test_non_divisible_width_preserves_fractional_cell_sizes() -> void:
	var viewport := Vector2(321.0, 200.0)
	var rect := _layout.get_item_rect(2, 3, viewport)
	assert_float(rect.size.x).is_equal_approx(301.0 / 3.0, 0.0001)
	assert_float(rect.end.x).is_equal_approx(321.0, 0.0001)


func test_content_height_is_independent_of_viewport_height() -> void:
	for viewport_height in [-1.0, 0.0, 10000.0]:
		var viewport := Vector2(320.0, viewport_height)
		assert_vector(_layout.get_content_size(10, viewport)).is_equal(Vector2(320.0, 424.0))


func test_invalid_configuration_is_clamped_on_assignment() -> void:
	for invalid_span_count in [0, -3]:
		_layout.span_count = invalid_span_count
		assert_int(_layout.span_count).is_equal(1)
	for invalid_height in [0.0, -10.0]:
		_layout.item_height = invalid_height
		assert_float(_layout.item_height).is_equal(1.0)
	_layout.spacing = Vector2(-10.0, -8.0)
	assert_vector(_layout.spacing).is_equal(Vector2.ZERO)
	assert_vector(_layout.get_content_size(2, VIEWPORT_SIZE)).is_equal(Vector2(320.0, 2.0))
	_layout.spacing = Vector2(5.0, -8.0)
	assert_vector(_layout.spacing).is_equal(Vector2(5.0, 0.0))
	_layout.spacing = Vector2(-5.0, 8.0)
	assert_vector(_layout.spacing).is_equal(Vector2(0.0, 8.0))


func test_insufficient_width_produces_an_empty_layout() -> void:
	for viewport_width in [-100.0, 0.0, 10.0, 20.0]:
		var viewport := Vector2(viewport_width, 200.0)
		assert_vector(_layout.get_content_size(10, viewport)).is_equal(Vector2.ZERO)
		_assert_rect(_layout.get_item_rect(0, 10, viewport), Rect2())
		assert_vector(_layout.get_visible_range(10, viewport, 0.0)).is_equal(Vector2i.ZERO)
	assert_vector(_layout.get_content_size(10, Vector2(21.0, 200.0))).is_equal(Vector2(21.0, 424.0))


func test_visible_ranges_respect_edges_gaps_and_unclamped_offsets() -> void:
	var cases := [
		[0.0, 100.0, Vector2i(0, 3)],
		[0.0, 108.0, Vector2i(0, 3)],
		[0.0, 108.25, Vector2i(0, 6)],
		[99.0, 10.0, Vector2i(0, 6)],
		[100.0, 8.0, Vector2i.ZERO],
		[100.0, 8.25, Vector2i(3, 6)],
		[101.0, 1.0, Vector2i.ZERO],
		[107.0, 1.0, Vector2i.ZERO],
		[108.0, 100.0, Vector2i(3, 6)],
		[108.0, 108.0, Vector2i(3, 6)],
		[108.0, 108.25, Vector2i(3, 9)],
		[324.0, 100.0, Vector2i(9, 10)],
		[423.0, 1.0, Vector2i(9, 10)],
		[424.0, 100.0, Vector2i.ZERO],
		[1000.0, 100.0, Vector2i.ZERO],
		[-100.0, 100.0, Vector2i.ZERO],
		[-99.0, 100.0, Vector2i(0, 3)],
		[0.0, 10000.0, Vector2i(0, 10)],
	]
	for test_case in cases:
		var offset: float = test_case[0]
		var viewport := Vector2(320.0, test_case[1])
		var expected: Vector2i = test_case[2]
		(
			assert_vector(_layout.get_visible_range(10, viewport, offset))
			. override_failure_message(
				"Unexpected visible range for offset %s and height %s" % [offset, viewport.y]
			)
			. is_equal(expected)
		)


func test_non_positive_viewport_height_has_no_visible_items() -> void:
	for viewport_height in [0.0, -1.0]:
		var viewport := Vector2(320.0, viewport_height)
		assert_vector(_layout.get_visible_range(10, viewport, 0.0)).is_equal(Vector2i.ZERO)


func test_large_dataset_can_be_queried_directly_at_the_end() -> void:
	var item_count := 1000000
	var viewport := Vector2(320.0, 100.0)
	assert_vector(_layout.get_content_size(item_count, viewport)).is_equal(
		Vector2(320.0, 36000064.0)
	)
	_assert_rect(
		_layout.get_item_rect(item_count - 1, item_count, viewport),
		Rect2(0.0, 35999964.0, 100.0, 100.0)
	)
	assert_vector(_layout.get_visible_range(item_count, viewport, 35999964.0)).is_equal(
		Vector2i(999999, 1000000)
	)


func test_configuration_changes_take_effect_on_the_next_query() -> void:
	_layout.get_content_size(10, VIEWPORT_SIZE)
	_layout.span_count = 2
	_layout.item_height = 50.0
	_layout.spacing = Vector2(20.0, 5.0)
	assert_vector(_layout.get_content_size(10, VIEWPORT_SIZE)).is_equal(Vector2(320.0, 270.0))
	_assert_rect(_layout.get_item_rect(3, 10, VIEWPORT_SIZE), Rect2(170.0, 55.0, 150.0, 50.0))
	assert_vector(_layout.get_visible_range(10, Vector2(320.0, 50.0), 55.0)).is_equal(
		Vector2i(2, 4)
	)


func test_visible_range_matches_brute_force_rectangle_intersection() -> void:
	_layout.item_height = 10.5
	_layout.spacing = Vector2(2.5, 3.25)
	for columns in [1, 4]:
		_layout.span_count = columns
		for item_count in [1, 19]:
			for viewport_height in [0.0, 1.0, 8.5, 31.0]:
				var viewport_size := Vector2(101.0, viewport_height)
				for offset in range(-20, 150, 3):
					var scroll_offset := offset + 0.25
					var viewport := Rect2(Vector2(0.0, scroll_offset), viewport_size)
					var expected := Vector2i.ZERO
					for position in range(item_count):
						var rect := _layout.get_item_rect(position, item_count, viewport_size)
						if viewport_height > 0.0 and rect.intersects(viewport):
							if expected == Vector2i.ZERO:
								expected.x = position
							expected.y = position + 1
					(
						assert_vector(
							_layout.get_visible_range(item_count, viewport_size, scroll_offset)
						)
						. override_failure_message(
							(
								"columns=%s count=%s height=%s offset=%s"
								% [columns, item_count, viewport_height, scroll_offset]
							)
						)
						. is_equal(expected)
					)


func _assert_rect(actual: Rect2, expected: Rect2) -> void:
	assert_vector(actual.position).is_equal(expected.position)
	assert_vector(actual.size).is_equal(expected.size)
