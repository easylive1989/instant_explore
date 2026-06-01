/// The circular "compass seal" brand mark, rendered inside a clay disc by the
/// `.brand .seal` / `.foot__brand .seal` containers.
export default function BrandSeal() {
  return (
    <svg
      viewBox="0 0 24 24"
      fill="none"
      stroke="#FBF1E9"
      strokeWidth="1.8"
      strokeLinecap="round"
      strokeLinejoin="round"
    >
      <circle cx="12" cy="12" r="9" />
      <polygon
        points="15.5 8.5 10.5 10.5 8.5 15.5 13.5 13.5"
        fill="#FBF1E9"
        stroke="none"
      />
    </svg>
  );
}
